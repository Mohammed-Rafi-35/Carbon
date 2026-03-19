from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.db.session import engine, Base
from app.core.config import settings
from app.api.v1 import worker, order, payout


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize database tables on startup"""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    await engine.dispose()


app = FastAPI(
    title="Carbon Parametric Insurance API",
    version="1.0.0",
    lifespan=lifespan,
)

# Register routers
app.include_router(worker.router, prefix="/api/v1")
app.include_router(order.router, prefix="/api/v1")
app.include_router(payout.router, prefix="/api/v1")


@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "environment": settings.ENVIRONMENT,
    }
