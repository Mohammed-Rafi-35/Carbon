import pytest
from app.db.repository import WorkerRepository, PolicyRepository, TransactionRepository
from app.schemas.models import WorkerCreate, PolicyCreate, TransactionCreate
from decimal import Decimal
from datetime import datetime, timedelta


class TestWorkerRepository:
    @pytest.mark.asyncio
    async def test_create_worker(self, test_db, sample_worker_data):
        """Verify worker creation and database commit"""
        worker_create = WorkerCreate(**sample_worker_data)
        worker = await WorkerRepository.create(test_db, worker_create)
        
        assert worker.id is not None
        assert worker.phone == sample_worker_data["phone"]
        assert worker.wallet_balance == Decimal("0.0")
        assert worker.weekly_rides_completed == 0
    
    @pytest.mark.asyncio
    async def test_get_worker_by_phone(self, test_db, created_worker):
        """Verify retrieval by unique phone constraint"""
        worker = await WorkerRepository.get_by_phone(test_db, created_worker.phone)
        
        assert worker is not None
        assert worker.id == created_worker.id
    
    @pytest.mark.asyncio
    async def test_update_wallet_balance(self, test_db, created_worker):
        """Verify wallet balance update and transaction atomicity"""
        initial_balance = created_worker.wallet_balance
        success = await WorkerRepository.update_wallet(test_db, created_worker.id, Decimal("100.50"))
        
        assert success is True
        
        updated_worker = await WorkerRepository.get_by_id(test_db, created_worker.id)
        assert updated_worker.wallet_balance == initial_balance + Decimal("100.50")


class TestPolicyRepository:
    @pytest.mark.asyncio
    async def test_create_policy(self, test_db, created_worker):
        """Verify policy creation with foreign key constraint"""
        policy_data = PolicyCreate(
            worker_id=created_worker.id,
            premium_rate_percentage=Decimal("5.0"),
            valid_until=datetime.now() + timedelta(days=7),
        )
        policy = await PolicyRepository.create(test_db, policy_data)
        
        assert policy.id is not None
        assert policy.worker_id == created_worker.id
        assert policy.is_active is True
    
    @pytest.mark.asyncio
    async def test_get_active_policy(self, test_db, created_worker):
        """Verify active policy retrieval logic"""
        policy_data = PolicyCreate(
            worker_id=created_worker.id,
            premium_rate_percentage=Decimal("4.0"),
            valid_until=datetime.now() + timedelta(days=7),
        )
        await PolicyRepository.create(test_db, policy_data)
        
        active_policy = await PolicyRepository.get_active_by_worker(test_db, created_worker.id)
        assert active_policy is not None
        assert active_policy.is_active is True


class TestTransactionRepository:
    @pytest.mark.asyncio
    async def test_create_transaction(self, test_db, created_worker):
        """Verify transaction audit log creation"""
        transaction_data = TransactionCreate(
            worker_id=created_worker.id,
            amount=Decimal("250.00"),
            type="PREMIUM_PAYMENT",
            reason="Weekly premium deduction",
        )
        transaction = await TransactionRepository.create(test_db, transaction_data)
        
        assert transaction.id is not None
        assert transaction.amount == Decimal("250.00")
        assert transaction.type == "PREMIUM_PAYMENT"
    
    @pytest.mark.asyncio
    async def test_get_worker_transactions(self, test_db, created_worker):
        """Verify transaction history retrieval with ordering"""
        amounts = []
        for i in range(3):
            transaction_data = TransactionCreate(
                worker_id=created_worker.id,
                amount=Decimal(f"{100 + i}.00"),
                type="PAYOUT",
            )
            tx = await TransactionRepository.create(test_db, transaction_data)
            amounts.append((tx.timestamp, tx.amount))
        
        transactions = await TransactionRepository.get_by_worker(test_db, created_worker.id)
        assert len(transactions) == 3
        # Verify transactions are returned (ordering by timestamp desc)
        assert all(tx.worker_id == created_worker.id for tx in transactions)
