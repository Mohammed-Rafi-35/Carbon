import pytest
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from app.db.session import Base
from app.db.models import Worker, Policy, Transaction
from decimal import Decimal
import uuid


TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"


@pytest.fixture
async def test_engine():
    engine = create_async_engine(TEST_DATABASE_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()


@pytest.fixture
async def test_db(test_engine):
    async_session = async_sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)
    async with async_session() as session:
        yield session


@pytest.fixture
def sample_worker_data():
    return {
        "phone": "+919876543210",
        "zone": "Mumbai-Central",
        "vehicle_type": "bike",
        "projected_weekly_income": Decimal("5000.00"),
    }


@pytest.fixture
async def created_worker(test_db, sample_worker_data):
    worker = Worker(**sample_worker_data)
    test_db.add(worker)
    await test_db.commit()
    await test_db.refresh(worker)
    return worker
