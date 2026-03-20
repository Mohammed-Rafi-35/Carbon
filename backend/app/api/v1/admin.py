"""
Phase 5 — Admin Command Center API
Provides real-time operational visibility, fraud quarantine queue,
financial pulse metrics, and diagnostic analytics.

All endpoints are prefixed /api/v1/admin and require the X-Admin-Key header.
"""
from fastapi import APIRouter, Depends, HTTPException, Header, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from app.db.session import get_db
from app.db.models import Worker, Policy, Transaction, RouteWeather
from app.core.config import settings
from datetime import datetime, timedelta
from decimal import Decimal
import json

router = APIRouter(prefix="/admin", tags=["Admin"])

# ── Auth Guard ────────────────────────────────────────────────────────────────

def _require_admin(x_admin_key: str = Header(None, alias="X-Admin-Key")):
    """Simple shared-secret admin gate. Replace with JWT in production."""
    if x_admin_key != settings.SECRET_KEY:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid or missing admin key",
        )


# ── Financial Pulse ───────────────────────────────────────────────────────────

@router.get("/dashboard", dependencies=[Depends(_require_admin)])
async def get_dashboard(db: AsyncSession = Depends(get_db)):
    """
    Real-time financial pulse for the admin command center.
    Returns aggregate metrics across all workers, policies, and transactions.
    """
    # Worker counts
    total_workers = (await db.execute(select(func.count(Worker.id)))).scalar_one()
    active_workers = (await db.execute(
        select(func.count(Worker.id)).where(Worker.is_active == True)
    )).scalar_one()

    # Policy counts
    active_policies = (await db.execute(
        select(func.count(Policy.id)).where(Policy.is_active == True)
    )).scalar_one()

    # Transaction aggregates
    payout_result = await db.execute(
        select(func.count(Transaction.id), func.coalesce(func.sum(Transaction.amount), 0))
        .where(Transaction.type == "PAYOUT")
    )
    payout_count, total_payout_amount = payout_result.one()

    premium_result = await db.execute(
        select(func.count(Transaction.id), func.coalesce(func.sum(Transaction.amount), 0))
        .where(Transaction.type == "PREMIUM_PAYMENT")
    )
    premium_count, total_premium_collected = premium_result.one()

    # Weather disruption stats
    disruption_result = await db.execute(
        select(func.count(RouteWeather.id))
        .where(RouteWeather.meets_threshold == True)
    )
    total_disruptions = disruption_result.scalar_one()

    total_orders = (await db.execute(select(func.count(RouteWeather.id)))).scalar_one()

    # Loss ratio: total payouts / total premiums collected
    loss_ratio = (
        float(total_payout_amount) / float(total_premium_collected)
        if total_premium_collected > 0
        else 0.0
    )

    # Recent 24h activity
    since_24h = datetime.utcnow() - timedelta(hours=24)
    recent_payouts = (await db.execute(
        select(func.count(Transaction.id))
        .where(and_(Transaction.type == "PAYOUT", Transaction.timestamp >= since_24h))
    )).scalar_one()

    recent_orders = (await db.execute(
        select(func.count(RouteWeather.id))
        .where(RouteWeather.timestamp >= since_24h)
    )).scalar_one()

    return {
        "generated_at": datetime.utcnow().isoformat(),
        "workers": {
            "total": total_workers,
            "active": active_workers,
            "inactive": total_workers - active_workers,
        },
        "policies": {
            "active": active_policies,
        },
        "financials": {
            "total_premiums_collected": float(total_premium_collected),
            "total_payouts_disbursed": float(total_payout_amount),
            "net_corpus": float(total_premium_collected) - float(total_payout_amount),
            "loss_ratio": round(loss_ratio, 4),
            "payout_count": payout_count,
            "premium_count": premium_count,
        },
        "disruptions": {
            "total_orders": total_orders,
            "threshold_met": total_disruptions,
            "disruption_rate": round(
                total_disruptions / total_orders if total_orders > 0 else 0.0, 4
            ),
        },
        "last_24h": {
            "payouts": recent_payouts,
            "orders": recent_orders,
        },
    }


# ── Fraud Quarantine Queue ────────────────────────────────────────────────────

@router.get("/fraud-queue", dependencies=[Depends(_require_admin)])
async def get_fraud_queue(db: AsyncSession = Depends(get_db), limit: int = 50):
    """
    Fraud Quarantine Queue — claims flagged by the sensor fusion gate.
    Returns rejected payout transactions with their fraud reason.
    """
    # Transactions with REJECTED type or reason containing fraud keywords
    result = await db.execute(
        select(Transaction, Worker.name, Worker.phone, Worker.zone)
        .join(Worker, Transaction.worker_id == Worker.id)
        .where(
            Transaction.type == "MANUAL_CLAIM"
        )
        .order_by(Transaction.timestamp.desc())
        .limit(limit)
    )
    rows = result.all()

    flagged = []
    for tx, name, phone, zone in rows:
        flagged.append({
            "transaction_id": str(tx.id),
            "worker_id": str(tx.worker_id),
            "worker_name": name,
            "worker_phone": phone,
            "worker_zone": zone,
            "amount": float(tx.amount),
            "reason": tx.reason,
            "timestamp": tx.timestamp.isoformat(),
            "status": "quarantined",
        })

    return {
        "total_flagged": len(flagged),
        "queue": flagged,
    }


# ── Disruption Analytics ──────────────────────────────────────────────────────

@router.get("/analytics/disruptions", dependencies=[Depends(_require_admin)])
async def get_disruption_analytics(
    db: AsyncSession = Depends(get_db),
    days: int = 7,
):
    """
    Diagnostic analytics — disruption intensity vs payout correlation.
    Compares total payouts against disruption events over the given window.
    """
    since = datetime.utcnow() - timedelta(days=days)

    # Disruption events in window
    disruption_rows = await db.execute(
        select(RouteWeather)
        .where(and_(RouteWeather.meets_threshold == True, RouteWeather.timestamp >= since))
        .order_by(RouteWeather.timestamp.desc())
    )
    disruptions = disruption_rows.scalars().all()

    # Payouts in window
    payout_rows = await db.execute(
        select(Transaction)
        .where(and_(Transaction.type == "PAYOUT", Transaction.timestamp >= since))
        .order_by(Transaction.timestamp.desc())
    )
    payouts = payout_rows.scalars().all()

    # Zone breakdown
    zone_stats: dict = {}
    for d in disruptions:
        weather = json.loads(d.weather_data)
        zone = weather.get("zone", "Unknown")
        if zone not in zone_stats:
            zone_stats[zone] = {"disruptions": 0, "payouts": 0, "payout_amount": 0.0}
        zone_stats[zone]["disruptions"] += 1

    for p in payouts:
        # Extract zone from reason if available
        zone_stats.setdefault("All Zones", {"disruptions": 0, "payouts": 0, "payout_amount": 0.0})
        zone_stats["All Zones"]["payouts"] += 1
        zone_stats["All Zones"]["payout_amount"] += float(p.amount)

    # Weather trigger breakdown
    trigger_counts: dict = {}
    for d in disruptions:
        reason = d.threshold_reason or "Unknown"
        for trigger in ["Heavy Rain", "High Wind", "Extreme Cold", "Extreme Heat"]:
            if trigger in reason:
                trigger_counts[trigger] = trigger_counts.get(trigger, 0) + 1

    return {
        "window_days": days,
        "since": since.isoformat(),
        "summary": {
            "total_disruptions": len(disruptions),
            "total_payouts": len(payouts),
            "total_payout_amount": sum(float(p.amount) for p in payouts),
        },
        "trigger_breakdown": trigger_counts,
        "zone_breakdown": zone_stats,
        "disruption_events": [
            {
                "order_id": d.order_id,
                "worker_id": str(d.worker_id),
                "zone": json.loads(d.weather_data).get("zone", "Unknown"),
                "reason": d.threshold_reason,
                "timestamp": d.timestamp.isoformat(),
            }
            for d in disruptions[:20]  # Cap at 20 for response size
        ],
    }


# ── Worker Management ─────────────────────────────────────────────────────────

@router.get("/workers", dependencies=[Depends(_require_admin)])
async def list_workers(
    db: AsyncSession = Depends(get_db),
    limit: int = 100,
    offset: int = 0,
):
    """List all workers with their financial summary."""
    result = await db.execute(
        select(Worker).order_by(Worker.created_at.desc()).limit(limit).offset(offset)
    )
    workers = result.scalars().all()
    total = (await db.execute(select(func.count(Worker.id)))).scalar_one()

    return {
        "total": total,
        "limit": limit,
        "offset": offset,
        "workers": [
            {
                "id": str(w.id),
                "name": w.name,
                "phone": w.phone,
                "zone": w.zone,
                "vehicle_type": w.vehicle_type,
                "wallet_balance": float(w.wallet_balance),
                "weekly_rides": w.weekly_rides_completed,
                "projected_income": float(w.projected_weekly_income or 0),
                "is_active": w.is_active,
                "joined": w.created_at.isoformat() if w.created_at else None,
            }
            for w in workers
        ],
    }


@router.patch("/workers/{worker_id}/deactivate", dependencies=[Depends(_require_admin)])
async def deactivate_worker(worker_id: str, db: AsyncSession = Depends(get_db)):
    """Deactivate a worker account (fraud or policy violation)."""
    import uuid as _uuid
    try:
        wid = _uuid.UUID(worker_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid worker ID")

    result = await db.execute(select(Worker).where(Worker.id == wid))
    worker = result.scalar_one_or_none()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")

    worker.is_active = False
    await db.commit()
    return {"message": f"Worker {worker_id} deactivated", "worker_id": worker_id}


@router.patch("/workers/{worker_id}/reactivate", dependencies=[Depends(_require_admin)])
async def reactivate_worker(worker_id: str, db: AsyncSession = Depends(get_db)):
    """Reactivate a previously deactivated worker."""
    import uuid as _uuid
    try:
        wid = _uuid.UUID(worker_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid worker ID")

    result = await db.execute(select(Worker).where(Worker.id == wid))
    worker = result.scalar_one_or_none()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")

    worker.is_active = True
    await db.commit()
    return {"message": f"Worker {worker_id} reactivated", "worker_id": worker_id}


# ── Data Transparency ─────────────────────────────────────────────────────────

@router.get("/workers/{worker_id}/data-report", dependencies=[Depends(_require_admin)])
async def get_worker_data_report(worker_id: str, db: AsyncSession = Depends(get_db)):
    """
    Full data transparency report for a worker.
    Shows exactly what data Carbon holds — GDPR-style data export.
    """
    import uuid as _uuid
    try:
        wid = _uuid.UUID(worker_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid worker ID")

    result = await db.execute(select(Worker).where(Worker.id == wid))
    worker = result.scalar_one_or_none()
    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")

    # All transactions
    tx_result = await db.execute(
        select(Transaction).where(Transaction.worker_id == wid)
        .order_by(Transaction.timestamp.desc())
    )
    transactions = tx_result.scalars().all()

    # All route weather records
    rw_result = await db.execute(
        select(RouteWeather).where(RouteWeather.worker_id == wid)
        .order_by(RouteWeather.timestamp.desc())
    )
    route_weathers = rw_result.scalars().all()

    # Active policy
    policy_result = await db.execute(
        select(Policy).where(and_(Policy.worker_id == wid, Policy.is_active == True))
    )
    policy = policy_result.scalar_one_or_none()

    return {
        "report_generated_at": datetime.utcnow().isoformat(),
        "worker": {
            "id": str(worker.id),
            "name": worker.name,
            "phone": worker.phone,
            "zone": worker.zone,
            "vehicle_type": worker.vehicle_type,
            "wallet_balance": float(worker.wallet_balance),
            "weekly_rides_completed": worker.weekly_rides_completed,
            "projected_weekly_income": float(worker.projected_weekly_income or 0),
            "is_active": worker.is_active,
            "joined_at": worker.created_at.isoformat() if worker.created_at else None,
        },
        "policy": {
            "id": str(policy.id) if policy else None,
            "is_active": policy.is_active if policy else False,
            "premium_rate_percent": float(policy.premium_rate_percentage) if policy else None,
            "valid_until": policy.valid_until.isoformat() if policy else None,
        },
        "sensor_data_policy": {
            "collected": ["GPS speed (scalar only)", "Accelerometer variance (scalar only)"],
            "not_collected": ["Raw GPS coordinates history", "Raw accelerometer readings", "Device identifiers"],
            "retention": "Sensor scalars are used only for fraud detection and are not stored post-validation",
            "purpose": "Anti-fraud kinematic analysis per DPDP Act 2023 compliance",
        },
        "transactions": [
            {
                "id": str(tx.id),
                "type": tx.type,
                "amount": float(tx.amount),
                "reason": tx.reason,
                "timestamp": tx.timestamp.isoformat(),
            }
            for tx in transactions
        ],
        "weather_snapshots": [
            {
                "order_id": rw.order_id,
                "meets_threshold": rw.meets_threshold,
                "threshold_reason": rw.threshold_reason,
                "timestamp": rw.timestamp.isoformat(),
            }
            for rw in route_weathers
        ],
    }
