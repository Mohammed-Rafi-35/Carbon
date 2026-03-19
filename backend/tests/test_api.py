import pytest
from httpx import AsyncClient
from app.main import app
from app.db.repository import WorkerRepository, RouteWeatherRepository
from app.schemas.models import WorkerCreate
from decimal import Decimal


class TestOrderEndpoints:
    @pytest.mark.asyncio
    async def test_receive_order_success(self, test_db, created_worker):
        """Test successful order reception with weather generation"""
        async with AsyncClient(app=app, base_url="http://test") as client:
            order_payload = {
                "worker_id": str(created_worker.id),
                "order_id": "ORDER_12345",
                "pickup_lat": 19.0760,
                "pickup_lon": 72.8777,
                "dropoff_lat": 19.1136,
                "dropoff_lon": 72.8697,
            }
            
            # Override get_db dependency
            from app.db.session import get_db
            app.dependency_overrides[get_db] = lambda: test_db
            
            response = await client.post("/api/v1/orders/receive", json=order_payload)
            
            assert response.status_code == 201
            data = response.json()
            
            # Verify weather data structure
            assert "temperature_celsius" in data
            assert "rain_mm" in data
            assert "humidity_percent" in data
            assert "wind_speed_kmh" in data
            assert "meets_threshold" in data
            assert "threshold_reason" in data
            assert data["zone"] == created_worker.zone
            
            # Verify data was stored
            route_weather = await RouteWeatherRepository.get_by_order(test_db, "ORDER_12345")
            assert route_weather is not None
            assert route_weather.worker_id == created_worker.id
            
            app.dependency_overrides.clear()
    
    @pytest.mark.asyncio
    async def test_receive_order_invalid_worker(self, test_db):
        """Test order reception with non-existent worker"""
        async with AsyncClient(app=app, base_url="http://test") as client:
            import uuid
            fake_worker_id = str(uuid.uuid4())
            
            order_payload = {
                "worker_id": fake_worker_id,
                "order_id": "ORDER_99999",
                "pickup_lat": 19.0760,
                "pickup_lon": 72.8777,
                "dropoff_lat": 19.1136,
                "dropoff_lon": 72.8697,
            }
            
            from app.db.session import get_db
            app.dependency_overrides[get_db] = lambda: test_db
            
            response = await client.post("/api/v1/orders/receive", json=order_payload)
            
            assert response.status_code == 404
            assert "not found" in response.json()["detail"].lower()
            
            app.dependency_overrides.clear()
    
    @pytest.mark.asyncio
    async def test_receive_order_invalid_coordinates(self, test_db, created_worker):
        """Test order reception with invalid GPS coordinates"""
        async with AsyncClient(app=app, base_url="http://test") as client:
            order_payload = {
                "worker_id": str(created_worker.id),
                "order_id": "ORDER_INVALID",
                "pickup_lat": 95.0,  # Invalid latitude (> 90)
                "pickup_lon": 72.8777,
                "dropoff_lat": 19.1136,
                "dropoff_lon": 72.8697,
            }
            
            from app.db.session import get_db
            app.dependency_overrides[get_db] = lambda: test_db
            
            response = await client.post("/api/v1/orders/receive", json=order_payload)
            
            assert response.status_code == 422  # Validation error
            
            app.dependency_overrides.clear()
    
    @pytest.mark.asyncio
    async def test_get_order_weather(self, test_db, created_worker):
        """Test retrieval of stored weather data"""
        # First create an order
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
        
        async with AsyncClient(app=app, base_url="http://test") as client:
            from app.db.session import get_db
            app.dependency_overrides[get_db] = lambda: test_db
            
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
        async with AsyncClient(app=app, base_url="http://test") as client:
            from app.db.session import get_db
            app.dependency_overrides[get_db] = lambda: test_db
            
            response = await client.get("/api/v1/orders/weather/NONEXISTENT_ORDER")
            
            assert response.status_code == 404
            
            app.dependency_overrides.clear()


class TestWorkerEndpoints:
    @pytest.mark.asyncio
    async def test_register_worker_success(self, test_db):
        """Test successful worker registration"""
        async with AsyncClient(app=app, base_url="http://test") as client:
            worker_payload = {
                "phone": "+919123456789",
                "zone": "Delhi-North",
                "vehicle_type": "bike",
                "projected_weekly_income": 6000.00,
            }
            
            from app.db.session import get_db
            app.dependency_overrides[get_db] = lambda: test_db
            
            response = await client.post("/api/v1/workers/register", json=worker_payload)
            
            assert response.status_code == 201
            data = response.json()
            
            assert data["phone"] == "+919123456789"
            assert data["zone"] == "Delhi-North"
            assert data["wallet_balance"] == "0.00"
            assert data["weekly_rides_completed"] == 0
            
            app.dependency_overrides.clear()
    
    @pytest.mark.asyncio
    async def test_register_worker_duplicate_phone(self, test_db, created_worker):
        """Test duplicate phone registration prevention"""
        async with AsyncClient(app=app, base_url="http://test") as client:
            worker_payload = {
                "phone": created_worker.phone,  # Duplicate
                "zone": "Mumbai-South",
                "vehicle_type": "scooter",
            }
            
            from app.db.session import get_db
            app.dependency_overrides[get_db] = lambda: test_db
            
            response = await client.post("/api/v1/workers/register", json=worker_payload)
            
            assert response.status_code == 409  # Conflict
            assert "already exists" in response.json()["detail"]
            
            app.dependency_overrides.clear()
    
    @pytest.mark.asyncio
    async def test_get_worker_by_id(self, test_db, created_worker):
        """Test worker retrieval by ID"""
        async with AsyncClient(app=app, base_url="http://test") as client:
            from app.db.session import get_db
            app.dependency_overrides[get_db] = lambda: test_db
            
            response = await client.get(f"/api/v1/workers/{created_worker.id}")
            
            assert response.status_code == 200
            data = response.json()
            
            assert data["id"] == str(created_worker.id)
            assert data["phone"] == created_worker.phone
            
            app.dependency_overrides.clear()
    
    @pytest.mark.asyncio
    async def test_get_worker_by_phone(self, test_db, created_worker):
        """Test worker retrieval by phone number"""
        async with AsyncClient(app=app, base_url="http://test") as client:
            from app.db.session import get_db
            app.dependency_overrides[get_db] = lambda: test_db
            
            response = await client.get(f"/api/v1/workers/phone/{created_worker.phone}")
            
            assert response.status_code == 200
            data = response.json()
            
            assert data["phone"] == created_worker.phone
            
            app.dependency_overrides.clear()
