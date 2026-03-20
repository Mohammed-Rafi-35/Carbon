from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.db.repository import WorkerRepository, RouteWeatherRepository
from app.schemas.models import OrderReceive, OrderResponse, WeatherResponse
from app.services.weather_svc import WeatherSynthesizer
from datetime import datetime, timezone
import uuid

router = APIRouter(prefix="/orders", tags=["Orders"])


@router.post("/receive", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
async def receive_order(
    order_data: OrderReceive,
    db: AsyncSession = Depends(get_db)
):
    """
    Receive order from aggregator app and generate weather conditions.

    Phase 2 — Parametric Logic:
    1. Validate worker exists
    2. Synthesize weather for pickup coordinates
    3. Evaluate payout threshold (rain >= 5mm, wind >= 40 km/h, temp extremes)
    4. Persist RouteWeather snapshot
    5. Return Order-shaped response with embedded weather
    """
    worker = await WorkerRepository.get_by_id(db, order_data.worker_id)
    if not worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Worker {order_data.worker_id} not found"
        )

    weather_data = WeatherSynthesizer.generate_weather(
        lat=order_data.pickup_lat,
        lon=order_data.pickup_lon,
        zone=worker.zone
    )

    meets_threshold, threshold_reason = WeatherSynthesizer.check_payout_threshold(weather_data)

    await RouteWeatherRepository.create(
        db=db,
        worker_id=order_data.worker_id,
        order_id=order_data.order_id,
        pickup_lat=order_data.pickup_lat,
        pickup_lon=order_data.pickup_lon,
        dropoff_lat=order_data.dropoff_lat,
        dropoff_lon=order_data.dropoff_lon,
        weather_data=weather_data,
        meets_threshold=meets_threshold,
        threshold_reason=threshold_reason,
    )

    weather_response = WeatherResponse(
        **weather_data,
        meets_threshold=meets_threshold,
        threshold_reason=threshold_reason,
    )

    return OrderResponse(
        id=order_data.order_id,
        worker_id=str(order_data.worker_id),
        pickup_lat=order_data.pickup_lat,
        pickup_lon=order_data.pickup_lon,
        dropoff_lat=order_data.dropoff_lat,
        dropoff_lon=order_data.dropoff_lon,
        status="active",
        created_at=datetime.now(timezone.utc).isoformat(),
        weather=weather_response,
    )


@router.get("/weather/{order_id}", response_model=WeatherResponse)
async def get_order_weather(
    order_id: str,
    db: AsyncSession = Depends(get_db)
):
    """
    Retrieve stored weather snapshot for a specific order.
    Used for lazy loading in mobile client.
    """
    route_weather = await RouteWeatherRepository.get_by_order(db, order_id)

    if not route_weather:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Weather data for order {order_id} not found"
        )

    import json
    weather_data = json.loads(route_weather.weather_data)

    return WeatherResponse(
        **weather_data,
        meets_threshold=route_weather.meets_threshold,
        threshold_reason=route_weather.threshold_reason,
    )
