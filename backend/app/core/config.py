from pydantic_settings import BaseSettings
from typing import Literal


class Settings(BaseSettings):
    """
    Centralized configuration management with strict validation.
    Server fails to start if required environment variables are missing.
    """
    SUPABASE_URL: str
    SUPABASE_KEY: str
    DATABASE_URL: str
    SECRET_KEY: str
    ENVIRONMENT: Literal["development", "production"] = "development"
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
