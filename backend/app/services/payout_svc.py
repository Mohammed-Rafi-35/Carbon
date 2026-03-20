"""
Payout Service
Handles parametric payout calculation and processing.
"""
from decimal import Decimal
from typing import Tuple, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.repository import WorkerRepository, RouteWeatherRepository, PolicyRepository, TransactionRepository
from app.schemas.models import TransactionCreate
from app.core.constants import BASE_PAYOUT_PERCENTAGE
import uuid
import json


class PayoutService:
    """
    Parametric payout calculation and disbursement logic.
    """
    
    @staticmethod
    async def calculate_payout_amount(
        db: AsyncSession,
        worker_id: uuid.UUID,
        order_id: str
    ) -> Tuple[Optional[Decimal], str]:
        """
        Calculate payout amount based on worker's projected income and weather conditions.
        
        Args:
            db: Database session
            worker_id: Worker UUID
            order_id: Order ID to check weather conditions
        
        Returns:
            Tuple of (payout_amount, reason)
        """
        # Get worker data
        worker = await WorkerRepository.get_by_id(db, worker_id)
        if not worker:
            return None, "Worker not found"
        
        # Check if worker has active policy
        policy = await PolicyRepository.get_active_by_worker(db, worker_id)
        if not policy:
            return None, "No active policy found for worker"
        
        # Get weather data for the order
        route_weather = await RouteWeatherRepository.get_by_order(db, order_id)
        if not route_weather:
            return None, "Weather data not found for order"
        
        # Check if weather meets payout threshold
        if not route_weather.meets_threshold:
            return None, f"Weather conditions do not meet payout threshold: {route_weather.threshold_reason}"
        
        # Calculate payout (20% of projected weekly income)
        if not worker.projected_weekly_income:
            return None, "Worker has no projected weekly income set"
        
        payout_amount = worker.projected_weekly_income * Decimal(str(BASE_PAYOUT_PERCENTAGE))
        
        return payout_amount, f"Payout approved: {route_weather.threshold_reason}"
    
    @staticmethod
    async def process_payout(
        db: AsyncSession,
        worker_id: uuid.UUID,
        order_id: str,
        payout_amount: Decimal,
        reason: str
    ) -> uuid.UUID:
        """
        Process payout by updating wallet and creating transaction record.
        
        Args:
            db: Database session
            worker_id: Worker UUID
            order_id: Order ID
            payout_amount: Amount to disburse
            reason: Payout reason
        
        Returns:
            Transaction UUID
        """
        # Update worker wallet balance
        await WorkerRepository.update_wallet(db, worker_id, payout_amount)
        
        # Create transaction record
        transaction_data = TransactionCreate(
            worker_id=worker_id,
            amount=payout_amount,
            type="PAYOUT",
            reason=f"Order {order_id}: {reason}"
        )
        
        transaction = await TransactionRepository.create(db, transaction_data)
        
        return transaction.id
    
    @staticmethod
    async def trigger_payout(
        db: AsyncSession,
        worker_id: uuid.UUID,
        order_id: str,
        weather_override: bool = False
    ) -> Tuple[bool, Optional[Decimal], Optional[uuid.UUID], str]:
        """
        Complete payout trigger flow with validation.
        
        Args:
            db: Database session
            worker_id: Worker UUID
            order_id: Order ID
            weather_override: Admin override for weather check
        
        Returns:
            Tuple of (success, payout_amount, transaction_id, reason)
        """
        # Calculate payout amount
        payout_amount, reason = await PayoutService.calculate_payout_amount(
            db, worker_id, order_id
        )
        
        if payout_amount is None:
            return False, None, None, reason
        
        # Admin override for weather conditions (for testing/manual claims)
        if weather_override:
            reason = f"[ADMIN OVERRIDE] {reason}"
        
        # Process payout
        try:
            transaction_id = await PayoutService.process_payout(
                db, worker_id, order_id, payout_amount, reason
            )
            
            return True, payout_amount, transaction_id, reason
        
        except Exception as e:
            return False, None, None, f"Payout processing failed: {str(e)}"
    
    @staticmethod
    async def check_duplicate_payout(
        db: AsyncSession,
        worker_id: uuid.UUID,
        order_id: str
    ) -> bool:
        """
        Check if payout has already been processed for this order.
        
        Args:
            db: Database session
            worker_id: Worker UUID
            order_id: Order ID
        
        Returns:
            True if duplicate, False otherwise
        """
        transactions = await TransactionRepository.get_by_worker(db, worker_id, limit=100)
        
        for transaction in transactions:
            if transaction.type == "PAYOUT" and order_id in (transaction.reason or ""):
                return True
        
        return False
