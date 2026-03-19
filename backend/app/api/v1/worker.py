from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db
from app.db.repository import WorkerRepository
from app.schemas.models import WorkerCreate, WorkerResponse

router = APIRouter(prefix="/workers", tags=["Workers"])


@router.post("/register", response_model=WorkerResponse, status_code=status.HTTP_201_CREATED)
async def register_worker(
    worker_data: WorkerCreate,
    db: AsyncSession = Depends(get_db)
):
    """
    Register a new delivery worker.
    Validates unique phone constraint.
    """
    # Check if phone already exists
    existing_worker = await WorkerRepository.get_by_phone(db, worker_data.phone)
    if existing_worker:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Worker with phone {worker_data.phone} already exists"
        )
    
    worker = await WorkerRepository.create(db, worker_data)
    return worker


@router.get("/{worker_id}", response_model=WorkerResponse)
async def get_worker(
    worker_id: str,
    db: AsyncSession = Depends(get_db)
):
    """
    Retrieve worker profile by ID.
    """
    import uuid
    try:
        worker_uuid = uuid.UUID(worker_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid worker ID format"
        )
    
    worker = await WorkerRepository.get_by_id(db, worker_uuid)
    if not worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Worker {worker_id} not found"
        )
    
    return worker


@router.get("/phone/{phone}", response_model=WorkerResponse)
async def get_worker_by_phone(
    phone: str,
    db: AsyncSession = Depends(get_db)
):
    """
    Retrieve worker profile by phone number.
    Used for login/authentication flow.
    """
    worker = await WorkerRepository.get_by_phone(db, phone)
    if not worker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Worker with phone {phone} not found"
        )
    
    return worker
