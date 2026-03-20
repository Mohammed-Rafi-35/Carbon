from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.models import Worker, Policy, Transaction, RouteWeather
from app.schemas.models import WorkerCreate, PolicyCreate, TransactionCreate
from typing import Optional
from decimal import Decimal
import uuid
import json
import bcrypt


class WorkerRepository:
    @staticmethod
    def _hash_password(password: str) -> str:
        return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

    @staticmethod
    def _verify_password(password: str, password_hash: str) -> bool:
        return bcrypt.checkpw(password.encode(), password_hash.encode())

    @staticmethod
    async def create(db: AsyncSession, worker_data: WorkerCreate) -> Worker:
        data = worker_data.model_dump(exclude={'password'})
        data['password_hash'] = WorkerRepository._hash_password(worker_data.password)
        worker = Worker(**data)
        db.add(worker)
        await db.commit()
        await db.refresh(worker)
        return worker

    @staticmethod
    async def get_by_id(db: AsyncSession, worker_id: uuid.UUID) -> Optional[Worker]:
        result = await db.execute(select(Worker).where(Worker.id == worker_id))
        return result.scalar_one_or_none()

    @staticmethod
    async def get_by_phone(db: AsyncSession, phone: str) -> Optional[Worker]:
        result = await db.execute(select(Worker).where(Worker.phone == phone))
        return result.scalar_one_or_none()

    @staticmethod
    async def authenticate(db: AsyncSession, phone: str, password: str) -> Optional[Worker]:
        worker = await WorkerRepository.get_by_phone(db, phone)
        if worker and WorkerRepository._verify_password(password, worker.password_hash):
            return worker
        return None

    @staticmethod
    async def update_wallet(db: AsyncSession, worker_id: uuid.UUID, amount: Decimal) -> bool:
        worker = await WorkerRepository.get_by_id(db, worker_id)
        if worker:
            worker.wallet_balance += amount
            await db.commit()
            return True
        return False


class PolicyRepository:
    @staticmethod
    async def create(db: AsyncSession, policy_data: PolicyCreate) -> Policy:
        policy = Policy(**policy_data.model_dump())
        db.add(policy)
        await db.commit()
        await db.refresh(policy)
        return policy
    
    @staticmethod
    async def get_active_by_worker(db: AsyncSession, worker_id: uuid.UUID) -> Optional[Policy]:
        result = await db.execute(
            select(Policy).where(Policy.worker_id == worker_id, Policy.is_active == True)
        )
        return result.scalar_one_or_none()


class TransactionRepository:
    @staticmethod
    async def create(db: AsyncSession, transaction_data: TransactionCreate) -> Transaction:
        transaction = Transaction(**transaction_data.model_dump())
        db.add(transaction)
        await db.commit()
        await db.refresh(transaction)
        return transaction
    
    @staticmethod
    async def get_by_worker(db: AsyncSession, worker_id: uuid.UUID, limit: int = 50):
        result = await db.execute(
            select(Transaction)
            .where(Transaction.worker_id == worker_id)
            .order_by(Transaction.timestamp.desc())
            .limit(limit)
        )
        return result.scalars().all()


class RouteWeatherRepository:
    @staticmethod
    async def create(db: AsyncSession, worker_id: uuid.UUID, order_id: str,
                    pickup_lat: float, pickup_lon: float,
                    dropoff_lat: float, dropoff_lon: float,
                    weather_data: dict, meets_threshold: bool,
                    threshold_reason: str) -> RouteWeather:
        route_weather = RouteWeather(
            worker_id=worker_id,
            order_id=order_id,
            pickup_lat=pickup_lat,
            pickup_lon=pickup_lon,
            dropoff_lat=dropoff_lat,
            dropoff_lon=dropoff_lon,
            weather_data=json.dumps(weather_data),
            meets_threshold=meets_threshold,
            threshold_reason=threshold_reason,
        )
        db.add(route_weather)
        await db.commit()
        await db.refresh(route_weather)
        return route_weather
    
    @staticmethod
    async def get_by_order(db: AsyncSession, order_id: str) -> Optional[RouteWeather]:
        result = await db.execute(
            select(RouteWeather).where(RouteWeather.order_id == order_id)
        )
        return result.scalar_one_or_none()
