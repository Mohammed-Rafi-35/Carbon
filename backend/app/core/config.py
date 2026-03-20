from pydantic_settings import BaseSettings
from typing import Literal, Optional


class Settings(BaseSettings):
    """
    Centralized configuration management with strict validation.
    Server fails to start if required environment variables are missing.
    """
    # Database Configuration
    DATABASE_URL: str
    
    # Security
    SECRET_KEY: str
    
    # Environment
    ENVIRONMENT: Literal["development", "production"] = "development"
    
    # Supabase (Optional)
    SUPABASE_URL: Optional[str] = None
    SUPABASE_KEY: Optional[str] = None
    
    # Server Configuration
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    WORKERS: int = 4
    LOG_LEVEL: str = "info"
    
    # Weather Thresholds
    RAIN_THRESHOLD_MM: float = 5.0
    WIND_THRESHOLD_KMH: float = 30.0
    TEMP_THRESHOLD_C: float = 35.0
    
    # Payout Configuration
    BASE_PAYOUT_AMOUNT: float = 50.0
    MAX_PAYOUT_AMOUNT: float = 200.0
    
    # Sensor Fusion Thresholds
    MIN_GPS_SPEED_KMH: float = 5.0
    MAX_ACCELEROMETER_VARIANCE: float = 2.0
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
