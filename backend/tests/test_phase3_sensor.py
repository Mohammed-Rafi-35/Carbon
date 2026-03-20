"""
Phase 3 Tests — Sensor Fusion & Truthfulness Gate

Tests the full payout trigger endpoint with:
  - HMAC signature validation
  - Sensor fraud detection (GPS spoofing, stationary vibration)
  - Duplicate payout prevention
  - Complete end-to-end payout flow via HTTP
"""
import pytest
import json
import time
from decimal import Decimal
from datetime import datetime, timedelta
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.db.session import get_db
from app.db.repository import WorkerRepository, PolicyRepository, RouteWeatherRepository
from app.schemas.models import WorkerCreate, PolicyCreate
from app.core.security import HMACValidator


def _make_signed_payload(payload: dict) -> tuple[str, str, str]:
    """Helper: returns (payload_str, timestamp, signature)"""
    payload_str = json.dumps(payload, sort_keys=True)
    timestamp = str(int(time.time()))
    signature = HMACValidator.generate_signature(payload_str, timestamp)
    return payload_str, timestamp, signature


class TestPayoutTriggerEndpoint:
    """Phase 3: Full payout trigger endpoint with sensor + HMAC validation."""

    @pytest.mark.asyncio
    async def test_payout_trigger_no_hmac_valid_sensors(self, test_db, created_worker):
        """Dev mode: no HMAC headers, valid sensor data → payout succeeds if weather met."""
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db

        # Setup policy + weather
        await PolicyRepository.create(test_db, PolicyCreate(
            worker_id=created_worker.id,
            premium_rate_percentage=Decimal("5.0"),
            valid_until=datetime.now() + timedelta(days=7),
        ))
        await RouteWeatherRepository.create(
            db=test_db, worker_id=created_worker.id,
            order_id="P3_ORDER_001",
            pickup_lat=19.076, pickup_lon=72.877,
            dropoff_lat=19.113, dropoff_lon=72.869,
            weather_data={"rain_mm": 8.0, "temperature_celsius": 30.0},
            meets_threshold=True, threshold_reason="Heavy Rain (8.0mm)",
        )

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/payout/trigger", json={
                "worker_id": str(created_worker.id),
                "order_id": "P3_ORDER_001",
                "sensor_data": {
                    "gps_speed_kmh": 25.0,
                    "accelerometer_variance": 1.2,
                },
            })

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["payout_amount"] is not None
        assert float(data["payout_amount"]) == 1000.0  # 20% of 5000
        assert data["security_checks"]["sensor_valid"] is True
        app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_payout_trigger_gps_spoofing_rejected(self, test_db, created_worker):
        """Phase 3: GPS spoofing (high speed + low variance) must be rejected."""
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/payout/trigger", json={
                "worker_id": str(created_worker.id),
                "order_id": "P3_SPOOF_001",
                "sensor_data": {
                    "gps_speed_kmh": 35.0,       # High speed
                    "accelerometer_variance": 0.1, # But device is still → spoofing
                },
            })

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is False
        assert "GPS Spoofing" in data["reason"] or "Sensor" in data["reason"]
        assert data["security_checks"]["sensor_valid"] is False
        app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_payout_trigger_with_valid_hmac(self, test_db, created_worker):
        """Phase 3: Valid HMAC signature + valid sensors → passes security gate."""
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db

        await PolicyRepository.create(test_db, PolicyCreate(
            worker_id=created_worker.id,
            premium_rate_percentage=Decimal("5.0"),
            valid_until=datetime.now() + timedelta(days=7),
        ))
        await RouteWeatherRepository.create(
            db=test_db, worker_id=created_worker.id,
            order_id="P3_HMAC_001",
            pickup_lat=19.076, pickup_lon=72.877,
            dropoff_lat=19.113, dropoff_lon=72.869,
            weather_data={"rain_mm": 9.0},
            meets_threshold=True, threshold_reason="Heavy Rain (9.0mm)",
        )

        # Build the exact JSON string that httpx will send (no sort_keys)
        payload = {
            "worker_id": str(created_worker.id),
            "order_id": "P3_HMAC_001",
            "sensor_data": {"gps_speed_kmh": 20.0, "accelerometer_variance": 1.5},
        }
        # httpx serialises with json.dumps default (no sort_keys)
        payload_str = json.dumps(payload)
        timestamp = str(int(time.time()))
        signature = HMACValidator.generate_signature(payload_str, timestamp)

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post(
                "/api/v1/payout/trigger",
                json=payload,
                headers={"X-Timestamp": timestamp, "X-Signature": signature},
            )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["security_checks"]["hmac_valid"] is True
        assert data["security_checks"]["sensor_valid"] is True
        app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_payout_trigger_invalid_hmac_rejected(self, test_db, created_worker):
        """Phase 3: Tampered HMAC signature must be rejected."""
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post(
                "/api/v1/payout/trigger",
                json={
                    "worker_id": str(created_worker.id),
                    "order_id": "P3_TAMPER_001",
                    "sensor_data": {"gps_speed_kmh": 20.0, "accelerometer_variance": 1.5},
                },
                headers={
                    "X-Timestamp": str(int(time.time())),
                    "X-Signature": "0" * 64,  # Invalid signature
                },
            )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is False
        assert data["security_checks"]["hmac_valid"] is False
        app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_payout_trigger_duplicate_rejected(self, test_db, created_worker):
        """Phase 3: Second payout for same order must be rejected."""
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db

        await PolicyRepository.create(test_db, PolicyCreate(
            worker_id=created_worker.id,
            premium_rate_percentage=Decimal("5.0"),
            valid_until=datetime.now() + timedelta(days=7),
        ))
        await RouteWeatherRepository.create(
            db=test_db, worker_id=created_worker.id,
            order_id="P3_DUP_001",
            pickup_lat=19.076, pickup_lon=72.877,
            dropoff_lat=19.113, dropoff_lon=72.869,
            weather_data={"rain_mm": 8.0},
            meets_threshold=True, threshold_reason="Heavy Rain",
        )

        payload = {
            "worker_id": str(created_worker.id),
            "order_id": "P3_DUP_001",
            "sensor_data": {"gps_speed_kmh": 20.0, "accelerometer_variance": 1.5},
        }

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            r1 = await client.post("/api/v1/payout/trigger", json=payload)
            r2 = await client.post("/api/v1/payout/trigger", json=payload)

        assert r1.json()["success"] is True
        assert r2.json()["success"] is False
        assert "Duplicate" in r2.json()["reason"]
        app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_payout_trigger_stationary_vibration_rejected(self, test_db, created_worker):
        """Phase 3: Stationary device with artificial vibration must be rejected."""
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/payout/trigger", json={
                "worker_id": str(created_worker.id),
                "order_id": "P3_VIB_001",
                "sensor_data": {
                    "gps_speed_kmh": 0.0,          # Stationary
                    "accelerometer_variance": 3.0,  # But high variance → artificial
                },
            })

        data = response.json()
        assert data["success"] is False
        assert "Stationary Vibration" in data["reason"] or "Sensor" in data["reason"]
        app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_payout_trigger_weather_not_met(self, test_db, created_worker):
        """Phase 3: Valid sensors but weather threshold not met → payout denied."""
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db

        await PolicyRepository.create(test_db, PolicyCreate(
            worker_id=created_worker.id,
            premium_rate_percentage=Decimal("5.0"),
            valid_until=datetime.now() + timedelta(days=7),
        ))
        await RouteWeatherRepository.create(
            db=test_db, worker_id=created_worker.id,
            order_id="P3_NORMAL_001",
            pickup_lat=19.076, pickup_lon=72.877,
            dropoff_lat=19.113, dropoff_lon=72.869,
            weather_data={"rain_mm": 1.0},
            meets_threshold=False, threshold_reason="Normal conditions",
        )

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post("/api/v1/payout/trigger", json={
                "worker_id": str(created_worker.id),
                "order_id": "P3_NORMAL_001",
                "sensor_data": {"gps_speed_kmh": 20.0, "accelerometer_variance": 1.5},
            })

        data = response.json()
        assert data["success"] is False
        assert "threshold" in data["reason"].lower()
        app.dependency_overrides.clear()
