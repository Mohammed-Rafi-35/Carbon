from pydantic import BaseModel, Field, field_validator
from typing import Optional, Literal, Dict
from datetime import datetime
from decimal import Decimal
import uuid


class WorkerCreate(BaseModel):
    phone: str = Field(..., pattern=r"^\+?[1-9]\d{9,14}$")
    zone: str = Field(..., min_length=2, max_length=100)
    vehicle_type: Literal["bike", "scooter", "bicycle"]
    projected_weekly_income: Optional[Decimal] = None


class WorkerResponse(BaseModel):
    id: uuid.UUID
    phone: str
    zone: str
    vehicle_type: str
    wallet_balance: Decimal
    weekly_rides_completed: int
    projected_weekly_income: Optional[Decimal]
    
    class Config:
        from_attributes = True


class PolicyCreate(BaseModel):
    worker_id: uuid.UUID
    premium_rate_percentage: Decimal = Field(..., ge=0, le=100)
    valid_until: datetime


class PolicyResponse(BaseModel):
    id: uuid.UUID
    worker_id: uuid.UUID
    is_active: bool
    premium_rate_percentage: Decimal
    valid_until: datetime
    
    class Config:
        from_attributes = True


class TransactionCreate(BaseModel):
    worker_id: uuid.UUID
    amount: Decimal = Field(..., gt=0)
    type: Literal["PREMIUM_PAYMENT", "PAYOUT", "MANUAL_CLAIM"]
    reason: Optional[str] = Field(None, max_length=500)


class TransactionResponse(BaseModel):
    id: uuid.UUID
    worker_id: uuid.UUID
    amount: Decimal
    type: str
    reason: Optional[str]
    timestamp: datetime
    
    class Config:
        from_attributes = True


class OrderReceive(BaseModel):
    worker_id: uuid.UUID
    order_id: str = Field(..., min_length=1, max_length=100)
    pickup_lat: float = Field(..., ge=-90, le=90)
    pickup_lon: float = Field(..., ge=-180, le=180)
    dropoff_lat: float = Field(..., ge=-90, le=90)
    dropoff_lon: float = Field(..., ge=-180, le=180)


class WeatherResponse(BaseModel):
    temperature_celsius: float
    rain_mm: float
    humidity_percent: float
    wind_speed_kmh: float
    zone: str
    lat: float
    lon: float
    timestamp: str
    meets_threshold: bool
    threshold_reason: str


class SensorData(BaseModel):
    gps_speed_kmh: float = Field(..., ge=0, le=200)
    accelerometer_variance: float = Field(..., ge=0)
    gyroscope_variance: Optional[float] = Field(None, ge=0)
    timestamp_diff_ms: Optional[int] = Field(None, ge=0)


class PayoutTrigger(BaseModel):
    worker_id: uuid.UUID
    order_id: str = Field(..., min_length=1, max_length=100)
    sensor_data: SensorData
    weather_override: Optional[bool] = Field(False, description="Admin override for weather check")


class PayoutResponse(BaseModel):
    success: bool
    payout_amount: Optional[Decimal]
    transaction_id: Optional[uuid.UUID]
    reason: str
    security_checks: Dict[str, bool]
    timestamp: datetime
