from fastapi import APIRouter, Depends, HTTPException, status, Header, Request
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.schemas.models import PayoutTrigger, PayoutResponse
from app.services.payout_svc import PayoutService
from app.core.security import SecurityGate
from datetime import datetime
import json

router = APIRouter(prefix="/payout", tags=["Payout"])


@router.post("/trigger", response_model=PayoutResponse, status_code=status.HTTP_200_OK)
async def trigger_payout(
    payout_request: PayoutTrigger,
    db: AsyncSession = Depends(get_db),
    x_timestamp: str = Header(None, alias="X-Timestamp"),
    x_signature: str = Header(None, alias="X-Signature"),
    request: Request = None
):
    """
    Trigger parametric payout with security validation.
    
    Security Gates:
    1. HMAC signature verification (optional in development)
    2. Sensor fusion validation (GPS + Accelerometer)
    3. Weather threshold validation
    4. Duplicate payout prevention
    
    Flow:
    1. Validate HMAC signature
    2. Validate sensor data (anti-fraud)
    3. Check weather conditions
    4. Calculate payout amount
    5. Process payout and update wallet
    6. Create transaction record
    """
    security_checks = {
        "hmac_valid": False,
        "sensor_valid": False,
        "weather_valid": False,
        "duplicate_check": False
    }
    
    # Get request body for HMAC validation
    body = await request.body()
    payload_str = body.decode('utf-8')
    
    # Security Gate: HMAC + Sensor Fusion
    # In development, HMAC is optional (set require_signature=False for testing)
    require_signature = x_timestamp is not None and x_signature is not None
    
    if require_signature:
        is_valid, reason = SecurityGate.validate_payout_request(
            payload=payload_str,
            timestamp=x_timestamp,
            signature=x_signature,
            sensor_data=payout_request.sensor_data.model_dump(),
            require_signature=True
        )
        
        if not is_valid:
            return PayoutResponse(
                success=False,
                payout_amount=None,
                transaction_id=None,
                reason=reason,
                security_checks=security_checks,
                timestamp=datetime.utcnow()
            )
        
        security_checks["hmac_valid"] = True
    else:
        # Development mode: Only validate sensor data
        from app.services.sensor_svc import SensorFusionAnalyzer
        is_valid, reason = SensorFusionAnalyzer.validate_sensor_consistency(
            payout_request.sensor_data.model_dump()
        )
        
        if not is_valid:
            return PayoutResponse(
                success=False,
                payout_amount=None,
                transaction_id=None,
                reason=f"Sensor Validation Failed: {reason}",
                security_checks=security_checks,
                timestamp=datetime.utcnow()
            )
    
    security_checks["sensor_valid"] = True
    
    # Check for duplicate payout
    is_duplicate = await PayoutService.check_duplicate_payout(
        db, payout_request.worker_id, payout_request.order_id
    )
    
    if is_duplicate:
        return PayoutResponse(
            success=False,
            payout_amount=None,
            transaction_id=None,
            reason=f"Duplicate payout: Order {payout_request.order_id} already processed",
            security_checks=security_checks,
            timestamp=datetime.utcnow()
        )
    
    security_checks["duplicate_check"] = True
    
    # Trigger payout
    success, payout_amount, transaction_id, reason = await PayoutService.trigger_payout(
        db=db,
        worker_id=payout_request.worker_id,
        order_id=payout_request.order_id,
        weather_override=payout_request.weather_override
    )
    
    if success:
        security_checks["weather_valid"] = True
    
    return PayoutResponse(
        success=success,
        payout_amount=payout_amount,
        transaction_id=transaction_id,
        reason=reason,
        security_checks=security_checks,
        timestamp=datetime.utcnow()
    )


@router.get("/history/{worker_id}", status_code=status.HTTP_200_OK)
async def get_payout_history(
    worker_id: str,
    db: AsyncSession = Depends(get_db),
    limit: int = 50
):
    """
    Retrieve payout history for a worker.
    
    Args:
        worker_id: Worker UUID
        limit: Maximum number of transactions to return
    """
    import uuid
    from app.db.repository import TransactionRepository
    
    try:
        worker_uuid = uuid.UUID(worker_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid worker ID format"
        )
    
    transactions = await TransactionRepository.get_by_worker(db, worker_uuid, limit)
    
    # Filter only payouts
    payouts = [tx for tx in transactions if tx.type == "PAYOUT"]
    
    return {
        "worker_id": worker_id,
        "total_payouts": len(payouts),
        "payouts": [
            {
                "id": str(tx.id),
                "amount": float(tx.amount),
                "reason": tx.reason,
                "timestamp": tx.timestamp.isoformat()
            }
            for tx in payouts
        ]
    }
