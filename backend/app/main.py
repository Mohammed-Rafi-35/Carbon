from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging
import socket
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from app.db.session import engine, Base, get_db
from app.core.config import settings
from app.api.v1 import worker, order, payout, admin

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL.upper()),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def _get_host_ip() -> str:
    """Detect the host machine's LAN IP — works inside Docker and bare-metal."""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            return s.getsockname()[0]
    except Exception:
        return "127.0.0.1"


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize database tables on startup and log network access info."""
    host_ip = _get_host_ip()
    logger.info(f"🚀 Starting Carbon API in {settings.ENVIRONMENT} mode")
    logger.info(f"📊 Database: {settings.DATABASE_URL.split('@')[1] if '@' in settings.DATABASE_URL else 'SQLite'}")
    logger.info(f"🌐 LAN access: http://{host_ip}:{settings.PORT}/api/v1")
    logger.info(f"📚 API docs:   http://{host_ip}:{settings.PORT}/docs")

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    logger.info("✅ Database tables initialized")

    yield

    logger.info("🛑 Shutting down Carbon API")
    await engine.dispose()


app = FastAPI(
    title="Carbon Parametric Insurance API",
    version="2.0.0",
    description="Production-ready parametric insurance API for delivery workers",
    lifespan=lifespan,
)

# CORS Configuration for mobile app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(worker.router, prefix="/api/v1")
app.include_router(order.router, prefix="/api/v1")
app.include_router(payout.router, prefix="/api/v1")
app.include_router(admin.router, prefix="/api/v1")


@app.get("/health")
async def health_check(db: AsyncSession = Depends(get_db)):
    """Health check endpoint — verifies API and DB connectivity."""
    try:
        await db.execute(text("SELECT 1"))
        db_status = "healthy"
    except Exception:
        db_status = "unhealthy"
    return {
        "status": "healthy" if db_status == "healthy" else "degraded",
        "database": db_status,
        "environment": settings.ENVIRONMENT,
        "version": "2.0.0",
        "host_ip": _get_host_ip(),
    }


@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "message": "Carbon Parametric Insurance API",
        "version": "2.0.0",
        "docs": "/docs",
        "health": "/health",
    }
