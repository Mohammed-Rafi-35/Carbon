from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.db.repository import WorkerRepository, PolicyRepository
from app.schemas.models import WorkerCreate, WorkerLogin, WorkerResponse, PolicyCreate, PolicyResponse
from app.services.premium_svc import PremiumService
import uuid

router = APIRouter(prefix="/workers", tags=["Workers"])


# ── Auth ──────────────────────────────────────────────────────────────────────

@router.post("/register", response_model=WorkerResponse, status_code=status.HTTP_201_CREATED)
async def register_worker(worker_data: WorkerCreate, db: AsyncSession = Depends(get_db)):
    existing = await WorkerRepository.get_by_phone(db, worker_data.phone)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Worker with phone {worker_data.phone} already exists",
        )
    return await WorkerRepository.create(db, worker_data)


@router.post("/login", response_model=WorkerResponse)
async def login_worker(credentials: WorkerLogin, db: AsyncSession = Depends(get_db)):
    worker = await WorkerRepository.authenticate(db, credentials.phone, credentials.password)
    if not worker:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid phone number or password",
        )
    if not worker.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is deactivated",
        )
    return worker


# ── Worker Lookup ─────────────────────────────────────────────────────────────

@router.get("/phone/{phone}", response_model=WorkerResponse)
async def get_worker_by_phone(phone: str, db: AsyncSession = Depends(get_db)):
    worker = await WorkerRepository.get_by_phone(db, phone)
    if not worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Worker with phone {phone} not found",
        )
    return worker


@router.get("/{worker_id}", response_model=WorkerResponse)
async def get_worker(worker_id: str, db: AsyncSession = Depends(get_db)):
    worker_uuid = _parse_uuid(worker_id)
    worker = await WorkerRepository.get_by_id(db, worker_uuid)
    if not worker:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Worker {worker_id} not found")
    return worker


# ── Policy ────────────────────────────────────────────────────────────────────

@router.post("/{worker_id}/policy", response_model=PolicyResponse, status_code=status.HTTP_201_CREATED)
async def create_worker_policy(
    worker_id: str,
    policy_data: PolicyCreate,
    db: AsyncSession = Depends(get_db),
):
    """
    Assign an insurance policy to a worker.
    Phase 1 — Data Persistence: required before any payout can be triggered.
    """
    worker_uuid = _parse_uuid(worker_id)
    worker = await WorkerRepository.get_by_id(db, worker_uuid)
    if not worker:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Worker {worker_id} not found")

    policy_data_with_id = PolicyCreate(
        worker_id=worker_uuid,
        premium_rate_percentage=policy_data.premium_rate_percentage,
        valid_until=policy_data.valid_until,
    )
    return await PolicyRepository.create(db, policy_data_with_id)


@router.get("/{worker_id}/policy", response_model=PolicyResponse)
async def get_worker_policy(worker_id: str, db: AsyncSession = Depends(get_db)):
    """Get the active policy for a worker."""
    worker_uuid = _parse_uuid(worker_id)
    policy = await PolicyRepository.get_active_by_worker(db, worker_uuid)
    if not policy:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No active policy found for worker {worker_id}",
        )
    return policy


# ── Phase 4: Insurance Math ───────────────────────────────────────────────────

@router.get("/{worker_id}/insurance-summary")
async def get_insurance_summary(worker_id: str, db: AsyncSession = Depends(get_db)):
    """
    Phase 4 — Revenue Model & Corpus Strategy.

    Returns the complete insurance dashboard for a worker:
      - Current premium tier (TIER_1/2/3)
      - Active rate (standard or front-load)
      - Weekly premium amount
      - Payout potential (20% of projected income)
      - Front-load period status
      - Policy validity
      - Coverage summary
    """
    worker_uuid = _parse_uuid(worker_id)
    summary = await PremiumService.get_insurance_summary(db, worker_uuid)
    if not summary:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Worker {worker_id} not found")
    return summary


@router.post("/{worker_id}/rides/increment")
async def increment_rides(
    worker_id: str,
    db: AsyncSession = Depends(get_db),
    rides: int = 1,
):
    """
    Increment weekly ride count after a completed delivery.
    Recalculates premium tier automatically.
    """
    worker_uuid = _parse_uuid(worker_id)
    success, total_rides, message = await PremiumService.update_weekly_rides(db, worker_uuid, rides)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=message)
    return {"weekly_rides_completed": total_rides, "message": message}


@router.post("/{worker_id}/premium/deduct")
async def deduct_premium(
    worker_id: str,
    db: AsyncSession = Depends(get_db),
    front_load: bool = False,
):
    """
    Deduct weekly premium from worker wallet.
    Called at the start of each weekly cycle.
    """
    worker_uuid = _parse_uuid(worker_id)
    success, amount, message = await PremiumService.deduct_weekly_premium(db, worker_uuid, front_load)
    if not success:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=message)
    return {"amount_deducted": float(amount), "message": message}


@router.post("/{worker_id}/weekly-reset")
async def reset_weekly_cycle(worker_id: str, db: AsyncSession = Depends(get_db)):
    """
    Reset weekly ride counter and renew policy.
    Called by scheduled weekly cron job.
    """
    worker_uuid = _parse_uuid(worker_id)
    success = await PremiumService.reset_weekly_cycle(db, worker_uuid)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Worker {worker_id} not found")
    return {"message": "Weekly cycle reset. Rides counter cleared and policy renewed."}


# ── Helpers ───────────────────────────────────────────────────────────────────

def _parse_uuid(value: str) -> uuid.UUID:
    try:
        return uuid.UUID(value)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid worker ID format")
