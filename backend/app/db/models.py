from sqlalchemy import Column, String, Integer, Numeric, Boolean, TIMESTAMP, ForeignKey, Float, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from sqlalchemy import TypeDecorator, CHAR
import uuid
from app.db.session import Base


class GUID(TypeDecorator):
    """Platform-independent GUID type. Uses PostgreSQL's UUID type, otherwise uses CHAR(36)."""
    impl = CHAR
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == 'postgresql':
            return dialect.type_descriptor(UUID(as_uuid=True))
        else:
            return dialect.type_descriptor(CHAR(36))

    def process_bind_param(self, value, dialect):
        if value is None:
            return value
        elif dialect.name == 'postgresql':
            return str(value)
        else:
            if not isinstance(value, uuid.UUID):
                return str(uuid.UUID(value))
            else:
                return str(value)

    def process_result_value(self, value, dialect):
        if value is None:
            return value
        else:
            if not isinstance(value, uuid.UUID):
                return uuid.UUID(value)
            else:
                return value


class Worker(Base):
    __tablename__ = "workers"
    
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False)
    phone = Column(String(15), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    zone = Column(String(100), nullable=False, index=True)
    vehicle_type = Column(String(50), nullable=False)
    wallet_balance = Column(Numeric(10, 2), default=0.0, nullable=False)
    weekly_rides_completed = Column(Integer, default=0, nullable=False)
    projected_weekly_income = Column(Numeric(10, 2), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())


class Policy(Base):
    __tablename__ = "policies"
    
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    worker_id = Column(GUID(), ForeignKey("workers.id", ondelete="CASCADE"), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    premium_rate_percentage = Column(Numeric(5, 2), nullable=False)
    valid_until = Column(TIMESTAMP, nullable=False)
    created_at = Column(TIMESTAMP, server_default=func.now())


class Transaction(Base):
    __tablename__ = "transactions"
    
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    worker_id = Column(GUID(), ForeignKey("workers.id", ondelete="CASCADE"), nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    type = Column(String(50), nullable=False)  # PREMIUM_PAYMENT, PAYOUT, MANUAL_CLAIM
    reason = Column(String(500), nullable=True)
    timestamp = Column(TIMESTAMP, server_default=func.now(), nullable=False)


class RouteWeather(Base):
    __tablename__ = "route_weather"
    
    id = Column(GUID(), primary_key=True, default=uuid.uuid4)
    worker_id = Column(GUID(), ForeignKey("workers.id", ondelete="CASCADE"), nullable=False)
    order_id = Column(String(100), nullable=False, index=True)
    pickup_lat = Column(Float, nullable=False)
    pickup_lon = Column(Float, nullable=False)
    dropoff_lat = Column(Float, nullable=False)
    dropoff_lon = Column(Float, nullable=False)
    weather_data = Column(Text, nullable=False)  # JSON string
    meets_threshold = Column(Boolean, default=False)
    threshold_reason = Column(String(500), nullable=True)
    timestamp = Column(TIMESTAMP, server_default=func.now(), nullable=False)
