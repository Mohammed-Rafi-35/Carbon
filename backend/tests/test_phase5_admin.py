"""
Phase 5 Tests — Admin Command Center
Covers: dashboard metrics, fraud queue, disruption analytics,
        worker management (deactivate/reactivate), data transparency report.
"""
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from app.db.session import Base, get_db
from app.main import app
from app.db.repository import WorkerRepository, RouteWeatherRepository, TransactionRepository
from app.schemas.models import WorkerCreate, TransactionCreate
from decimal import Decimal
import uuid

TEST_DB_URL = "sqlite+aiosqlite:///:memory:"
ADMIN_KEY = "test-secret-key-for-testing-only"
ADMIN_HEADERS = {"X-Admin-Key": ADMIN_KEY}


@pytest_asyncio.fixture
async def engine():
    eng = create_async_engine(TEST_DB_URL, echo=False)
    async with eng.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield eng
    await eng.dispose()


@pytest_asyncio.fixture
async def db_session(engine):
    factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with factory() as session:
        yield session


@pytest_asyncio.fixture
async def client(engine):
    factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async def override_db():
        async with factory() as session:
            yield session

    app.dependency_overrides[get_db] = override_db
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def worker(db_session):
    wc = WorkerCreate(
        name="Admin Test Worker",
        phone="+919000000001",
        password="pass1234",
        zone="Delhi-North",
        vehicle_type="bike",
        projected_weekly_income=Decimal("4000.00"),
    )
    return await WorkerRepository.create(db_session, wc)


# ── Auth Guard ────────────────────────────────────────────────────────────────

class TestAdminAuth:
    async def test_dashboard_requires_admin_key(self, client):
        r = await client.get("/api/v1/admin/dashboard")
        assert r.status_code == 403

    async def test_dashboard_wrong_key_rejected(self, client):
        r = await client.get("/api/v1/admin/dashboard", headers={"X-Admin-Key": "wrong"})
        assert r.status_code == 403

    async def test_dashboard_valid_key_accepted(self, client):
        r = await client.get("/api/v1/admin/dashboard", headers=ADMIN_HEADERS)
        assert r.status_code == 200


# ── Dashboard ─────────────────────────────────────────────────────────────────

class TestAdminDashboard:
    async def test_dashboard_structure(self, client):
        r = await client.get("/api/v1/admin/dashboard", headers=ADMIN_HEADERS)
        data = r.json()
        assert "workers" in data
        assert "financials" in data
        assert "disruptions" in data
        assert "last_24h" in data
        assert "generated_at" in data

    async def test_dashboard_worker_counts(self, client, worker):
        r = await client.get("/api/v1/admin/dashboard", headers=ADMIN_HEADERS)
        data = r.json()
        assert data["workers"]["total"] >= 1
        assert data["workers"]["active"] >= 1

    async def test_dashboard_financials_keys(self, client):
        r = await client.get("/api/v1/admin/dashboard", headers=ADMIN_HEADERS)
        fin = r.json()["financials"]
        assert "total_premiums_collected" in fin
        assert "total_payouts_disbursed" in fin
        assert "net_corpus" in fin
        assert "loss_ratio" in fin

    async def test_dashboard_loss_ratio_zero_when_no_data(self, client):
        r = await client.get("/api/v1/admin/dashboard", headers=ADMIN_HEADERS)
        assert r.json()["financials"]["loss_ratio"] == 0.0

    async def test_dashboard_disruption_rate_zero_when_no_orders(self, client):
        r = await client.get("/api/v1/admin/dashboard", headers=ADMIN_HEADERS)
        assert r.json()["disruptions"]["disruption_rate"] == 0.0


# ── Fraud Queue ───────────────────────────────────────────────────────────────

class TestFraudQueue:
    async def test_fraud_queue_empty_initially(self, client):
        r = await client.get("/api/v1/admin/fraud-queue", headers=ADMIN_HEADERS)
        assert r.status_code == 200
        data = r.json()
        assert data["total_flagged"] == 0
        assert data["queue"] == []

    async def test_fraud_queue_shows_manual_claims(self, client, worker, db_session):
        # Create a MANUAL_CLAIM transaction (flagged fraud)
        tx = TransactionCreate(
            worker_id=worker.id,
            amount=Decimal("100.00"),
            type="MANUAL_CLAIM",
            reason="GPS Spoofing Detected: Speed 50 km/h but variance 0.1",
        )
        await TransactionRepository.create(db_session, tx)

        r = await client.get("/api/v1/admin/fraud-queue", headers=ADMIN_HEADERS)
        data = r.json()
        assert data["total_flagged"] == 1
        assert "GPS Spoofing" in data["queue"][0]["reason"]

    async def test_fraud_queue_requires_auth(self, client):
        r = await client.get("/api/v1/admin/fraud-queue")
        assert r.status_code == 403


# ── Analytics ─────────────────────────────────────────────────────────────────

class TestDisruptionAnalytics:
    async def test_analytics_structure(self, client):
        r = await client.get("/api/v1/admin/analytics/disruptions", headers=ADMIN_HEADERS)
        assert r.status_code == 200
        data = r.json()
        assert "window_days" in data
        assert "summary" in data
        assert "trigger_breakdown" in data
        assert "zone_breakdown" in data

    async def test_analytics_default_7_day_window(self, client):
        r = await client.get("/api/v1/admin/analytics/disruptions", headers=ADMIN_HEADERS)
        assert r.json()["window_days"] == 7

    async def test_analytics_custom_window(self, client):
        r = await client.get(
            "/api/v1/admin/analytics/disruptions?days=30", headers=ADMIN_HEADERS
        )
        assert r.json()["window_days"] == 30

    async def test_analytics_with_disruption_data(self, client, worker, db_session):
        await RouteWeatherRepository.create(
            db=db_session,
            worker_id=worker.id,
            order_id="ORD-TEST-001",
            pickup_lat=19.0760,
            pickup_lon=72.8777,
            dropoff_lat=19.0800,
            dropoff_lon=72.8800,
            weather_data={
                "temperature_celsius": 28.0,
                "rain_mm": 8.5,
                "humidity_percent": 90.0,
                "wind_speed_kmh": 45.0,
                "zone": "Mumbai-Central",
                "lat": 19.0760,
                "lon": 72.8777,
                "timestamp": "2024-01-01T10:00:00",
            },
            meets_threshold=True,
            threshold_reason="Heavy Rain (8.5mm) + High Wind (45.0 km/h)",
        )

        r = await client.get("/api/v1/admin/analytics/disruptions", headers=ADMIN_HEADERS)
        data = r.json()
        assert data["summary"]["total_disruptions"] >= 1


# ── Worker Management ─────────────────────────────────────────────────────────

class TestWorkerManagement:
    async def test_list_workers(self, client, worker):
        r = await client.get("/api/v1/admin/workers", headers=ADMIN_HEADERS)
        assert r.status_code == 200
        data = r.json()
        assert data["total"] >= 1
        assert len(data["workers"]) >= 1

    async def test_list_workers_structure(self, client, worker):
        r = await client.get("/api/v1/admin/workers", headers=ADMIN_HEADERS)
        w = r.json()["workers"][0]
        assert "id" in w
        assert "name" in w
        assert "wallet_balance" in w
        assert "is_active" in w

    async def test_deactivate_worker(self, client, worker):
        r = await client.patch(
            f"/api/v1/admin/workers/{worker.id}/deactivate", headers=ADMIN_HEADERS
        )
        assert r.status_code == 200
        assert "deactivated" in r.json()["message"]

    async def test_reactivate_worker(self, client, worker):
        # Deactivate first
        await client.patch(
            f"/api/v1/admin/workers/{worker.id}/deactivate", headers=ADMIN_HEADERS
        )
        # Then reactivate
        r = await client.patch(
            f"/api/v1/admin/workers/{worker.id}/reactivate", headers=ADMIN_HEADERS
        )
        assert r.status_code == 200
        assert "reactivated" in r.json()["message"]

    async def test_deactivate_nonexistent_worker(self, client):
        fake_id = str(uuid.uuid4())
        r = await client.patch(
            f"/api/v1/admin/workers/{fake_id}/deactivate", headers=ADMIN_HEADERS
        )
        assert r.status_code == 404

    async def test_invalid_worker_id_format(self, client):
        r = await client.patch(
            "/api/v1/admin/workers/not-a-uuid/deactivate", headers=ADMIN_HEADERS
        )
        assert r.status_code == 400


# ── Data Transparency ─────────────────────────────────────────────────────────

class TestDataTransparency:
    async def test_data_report_structure(self, client, worker):
        r = await client.get(
            f"/api/v1/admin/workers/{worker.id}/data-report", headers=ADMIN_HEADERS
        )
        assert r.status_code == 200
        data = r.json()
        assert "worker" in data
        assert "policy" in data
        assert "sensor_data_policy" in data
        assert "transactions" in data
        assert "weather_snapshots" in data

    async def test_data_report_sensor_policy_present(self, client, worker):
        r = await client.get(
            f"/api/v1/admin/workers/{worker.id}/data-report", headers=ADMIN_HEADERS
        )
        sp = r.json()["sensor_data_policy"]
        assert "collected" in sp
        assert "not_collected" in sp
        assert "retention" in sp
        assert "purpose" in sp

    async def test_data_report_worker_info_correct(self, client, worker):
        r = await client.get(
            f"/api/v1/admin/workers/{worker.id}/data-report", headers=ADMIN_HEADERS
        )
        w = r.json()["worker"]
        assert w["name"] == "Admin Test Worker"
        assert w["zone"] == "Delhi-North"

    async def test_data_report_404_for_unknown_worker(self, client):
        r = await client.get(
            f"/api/v1/admin/workers/{uuid.uuid4()}/data-report", headers=ADMIN_HEADERS
        )
        assert r.status_code == 404

    async def test_data_report_requires_auth(self, client, worker):
        r = await client.get(f"/api/v1/admin/workers/{worker.id}/data-report")
        assert r.status_code == 403
