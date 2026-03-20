import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.db.repository import WorkerRepository, RouteWeatherRepository
from app.schemas.models import WorkerCreate
from decimal import Decimal
from datetime import datetime, timedelta


class TestOrderEndpoints:
    @pytest.mark.asyncio
    async def test_receive_order_success(self, test_db, created_worker):
        """Test successful order reception with weather generation — returns OrderResponse"""
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            order_payload = {
                "worker_id": str(created_worker.id),
                "order_id": "ORDER_12345",
                "pickup_lat": 19.0760,
                "pickup_lon": 72.8777,
                "dropoff_lat": 19.1136,
                "dropoff_lon": 72.8697,
            }
            response = await client.post("/api/v1/orders/receive", json=order_payload)
            assert response.status_code == 201
            data = response.json()
            # OrderResponse fields
            assert data["id"] == "ORDER_12345"
            assert data["worker_id"] == str(created_worker.id)
            assert data["status"] == "active"
            assert "created_at" in data
            # Embedded weather
            assert data["weather"] is not None
            assert "temperature_celsius" in data["weather"]
            assert "rain_mm" in data["weather"]
            assert "humidity_percent" in data["weather"]
            assert "wind_speed_kmh" in data["weather"]
            assert "meets_threshold" in data["weather"]
            assert "threshold_reason" in data["weather"]
            assert data["weather"]["zone"] == created_worker.zone
            route_weather = await RouteWeatherRepository.get_by_order(test_db, "ORDER_12345")
            assert route_weather is not None
            assert route_weather.worker_id == created_worker.id
        app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_receive_order_invalid_worker(self, test_db):
        """Test order reception with non-existent worker"""
        import uuid
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            order_payload = {
                "worker_id": str(uuid.uuid4()),
                "order_id": "ORDER_99999",
                "pickup_lat": 19.0760,
                "pickup_lon": 72.8777,
                "dropoff_lat": 19.1136,
                "dropoff_lon": 72.8697,
            }
            response = await client.post("/api/v1/orders/receive", json=order_payload)
            assert response.status_code == 404
            assert "not found" in response.json()["detail"].lower()
        app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_receive_order_invalid_coordinates(self, test_db, created_worker):
        """Test order reception with invalid GPS coordinates"""
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            order_payload = {
                "worker_id": str(created_worker.id),
                "order_id": "ORDER_INVALID",
                "pickup_lat": 95.0,
                "pickup_lon": 72.8777,
                "dropoff_lat": 19.1136,
                "dropoff_lon": 72.8697,
            }
            response = await client.post("/api/v1/orders/receive", json=order_payload)
            assert response.status_code == 422
        app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_get_order_weather(self, test_db, created_worker):
        """Test retrieval of stored weather data"""
        await RouteWeatherRepository.create(
            db=test_db,
            worker_id=created_worker.id,
            order_id="ORDER_RETRIEVE_TEST",
            pickup_lat=19.0760,
            pickup_lon=72.8777,
            dropoff_lat=19.1136,
            dropoff_lon=72.8697,
            weather_data={
                "temperature_celsius": 32.5,
                "rain_mm": 7.2,
                "humidity_percent": 88.0,
                "wind_speed_kmh": 25.0,
                "zone": "Mumbai-Central",
                "lat": 19.0760,
                "lon": 72.8777,
                "timestamp": "2024-01-01T12:00:00",
            },
            meets_threshold=True,
            threshold_reason="Heavy Rain (7.2mm)",
        )
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.get("/api/v1/orders/weather/ORDER_RETRIEVE_TEST")
            assert response.status_code == 200
            data = response.json()
            assert data["rain_mm"] == 7.2
            assert data["meets_threshold"] is True
            assert "Heavy Rain" in data["threshold_reason"]
        app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_get_order_weather_not_found(self, test_db):
        """Test retrieval of non-existent order weather"""
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.get("/api/v1/orders/weather/NONEXISTENT_ORDER")
            assert response.status_code == 404
        app.dependency_overrides.clear()


class TestWorkerEndpoints:
    @pytest.mark.asyncio
    async def test_register_worker_success(self, test_db):
        """Test successful worker registration"""
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            worker_payload = {
                "name": "Test Worker",
                "phone": "+919123456789",
                "password": "securepass123",
                "zone": "Delhi-North",
                "vehicle_type": "bike",
                "projected_weekly_income": 6000.00,
            }
            response = await client.post("/api/v1/workers/register", json=worker_payload)
            assert response.status_code == 201
            data = response.json()
            assert data["phone"] == "+919123456789"
            assert data["zone"] == "Delhi-North"
            assert data["wallet_balance"] == "0.00"
            assert data["weekly_rides_completed"] == 0
            assert "password_hash" not in data
        app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_register_worker_duplicate_phone(self, test_db, created_worker):
        """Test duplicate phone registration prevention"""
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            worker_payload = {
                "name": "Duplicate Worker",
                "phone": created_worker.phone,
                "password": "securepass123",
                "zone": "Mumbai-South",
                "vehicle_type": "scooter",
            }
            response = await client.post("/api/v1/workers/register", json=worker_payload)
            assert response.status_code == 409
            assert "already exists" in response.json()["detail"]
        app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_login_worker_success(self, test_db):
        """Test successful login with correct credentials"""
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            await client.post("/api/v1/workers/register", json={
                "name": "Login Test", "phone": "+919000000001",
                "password": "mypassword", "zone": "South", "vehicle_type": "bike",
            })
            response = await client.post("/api/v1/workers/login", json={
                "phone": "+919000000001", "password": "mypassword",
            })
            assert response.status_code == 200
            assert response.json()["phone"] == "+919000000001"
            assert "password_hash" not in response.json()
        app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_login_worker_wrong_password(self, test_db):
        """Test login rejection with wrong password"""
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            await client.post("/api/v1/workers/register", json={
                "name": "Login Test 2", "phone": "+919000000002",
                "password": "correctpass", "zone": "North", "vehicle_type": "scooter",
            })
            response = await client.post("/api/v1/workers/login", json={
                "phone": "+919000000002", "password": "wrongpass",
            })
            assert response.status_code == 401
        app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_get_worker_by_id(self, test_db, created_worker):
        """Test worker retrieval by ID"""
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.get(f"/api/v1/workers/{created_worker.id}")
            assert response.status_code == 200
            data = response.json()
            assert data["id"] == str(created_worker.id)
            assert data["phone"] == created_worker.phone
        app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_get_worker_by_phone(self, test_db, created_worker):
        """Test worker retrieval by phone number"""
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.get(f"/api/v1/workers/phone/{created_worker.phone}")
            assert response.status_code == 200
            data = response.json()
            assert data["phone"] == created_worker.phone
        app.dependency_overrides.clear()


class TestPolicyEndpoints:
    @pytest.mark.asyncio
    async def test_create_worker_policy(self, test_db, created_worker):
        """Test policy creation for a worker — required for payout eligibility"""
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            policy_payload = {
                "worker_id": str(created_worker.id),
                "premium_rate_percentage": "5.00",
                "valid_until": (datetime.utcnow() + timedelta(days=7)).isoformat(),
            }
            response = await client.post(
                f"/api/v1/workers/{created_worker.id}/policy",
                json=policy_payload,
            )
            assert response.status_code == 201
            data = response.json()
            assert data["worker_id"] == str(created_worker.id)
            assert data["is_active"] is True
            assert float(data["premium_rate_percentage"]) == 5.0
        app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_get_worker_policy(self, test_db, created_worker):
        """Test active policy retrieval for a worker"""
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            # Create policy first
            policy_payload = {
                "worker_id": str(created_worker.id),
                "premium_rate_percentage": "4.00",
                "valid_until": (datetime.utcnow() + timedelta(days=7)).isoformat(),
            }
            await client.post(f"/api/v1/workers/{created_worker.id}/policy", json=policy_payload)

            # Retrieve it
            response = await client.get(f"/api/v1/workers/{created_worker.id}/policy")
            assert response.status_code == 200
            data = response.json()
            assert data["worker_id"] == str(created_worker.id)
            assert data["is_active"] is True
        app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_get_policy_not_found(self, test_db, created_worker):
        """Test 404 when worker has no active policy"""
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.get(f"/api/v1/workers/{created_worker.id}/policy")
            assert response.status_code == 404
            assert "No active policy" in response.json()["detail"]
        app.dependency_overrides.clear()
