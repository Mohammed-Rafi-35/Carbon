"""
Premium Service — Phase 4: Revenue Model & Corpus Strategy

Implements the full parametric insurance math:
  - Ride-based tier classification (100+/70-99/<70 rides/week)
  - Front-loading strategy for Month 1 corpus build (7/5/3%)
  - Standard rates post-corpus (5/4/3%)
  - Weekly premium deduction from projected income
  - Payout = 20% of projected weekly income
"""
from decimal import Decimal, ROUND_HALF_UP
from typing import Tuple, Optional, Dict
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.repository import WorkerRepository, PolicyRepository, TransactionRepository
from app.schemas.models import TransactionCreate, PolicyCreate
from app.core.constants import PREMIUM_TIERS, FRONT_LOAD_TIERS, BASE_PAYOUT_PERCENTAGE
from datetime import datetime, timedelta
import uuid


class PremiumTier:
    """Encapsulates a worker's current premium tier and rates."""

    def __init__(
        self,
        tier_name: str,
        weekly_rides: int,
        standard_rate: Decimal,
        front_load_rate: Decimal,
        is_front_load_period: bool,
    ):
        self.tier_name = tier_name
        self.weekly_rides = weekly_rides
        self.standard_rate = standard_rate
        self.front_load_rate = front_load_rate
        self.is_front_load_period = is_front_load_period

    @property
    def active_rate(self) -> Decimal:
        return self.front_load_rate if self.is_front_load_period else self.standard_rate

    @property
    def active_rate_percent(self) -> float:
        return float(self.active_rate * 100)

    def to_dict(self) -> Dict:
        return {
            "tier_name": self.tier_name,
            "weekly_rides": self.weekly_rides,
            "standard_rate_percent": float(self.standard_rate * 100),
            "front_load_rate_percent": float(self.front_load_rate * 100),
            "active_rate_percent": self.active_rate_percent,
            "is_front_load_period": self.is_front_load_period,
        }


class PremiumService:
    """
    Phase 4 insurance math engine.

    Corpus Strategy:
      Month 1 (front-load): Tier1=7%, Tier2=5%, Tier3=3%
      Ongoing:              Tier1=5%, Tier2=4%, Tier3=3%

    Payout = 20% of projected_weekly_income (BASE_PAYOUT_PERCENTAGE)
    """

    @staticmethod
    def classify_tier(weekly_rides: int, is_front_load: bool = False) -> PremiumTier:
        """
        Classify worker into premium tier based on weekly ride count.

        Tier 1: 100+ rides → 5% (7% front-load)
        Tier 2: 70–99 rides → 4% (5% front-load)
        Tier 3: <70 rides  → 3% (3% front-load)
        """
        if weekly_rides >= PREMIUM_TIERS["TIER_1"]["min_rides"]:
            return PremiumTier(
                tier_name="TIER_1",
                weekly_rides=weekly_rides,
                standard_rate=Decimal(str(PREMIUM_TIERS["TIER_1"]["rate"])),
                front_load_rate=Decimal(str(FRONT_LOAD_TIERS["TIER_1"])),
                is_front_load_period=is_front_load,
            )
        elif weekly_rides >= PREMIUM_TIERS["TIER_2"]["min_rides"]:
            return PremiumTier(
                tier_name="TIER_2",
                weekly_rides=weekly_rides,
                standard_rate=Decimal(str(PREMIUM_TIERS["TIER_2"]["rate"])),
                front_load_rate=Decimal(str(FRONT_LOAD_TIERS["TIER_2"])),
                is_front_load_period=is_front_load,
            )
        else:
            return PremiumTier(
                tier_name="TIER_3",
                weekly_rides=weekly_rides,
                standard_rate=Decimal(str(PREMIUM_TIERS["TIER_3"]["rate"])),
                front_load_rate=Decimal(str(FRONT_LOAD_TIERS["TIER_3"])),
                is_front_load_period=is_front_load,
            )

    @staticmethod
    def calculate_weekly_premium(
        projected_weekly_income: Decimal,
        tier: PremiumTier,
    ) -> Decimal:
        """
        Calculate weekly premium amount.
        premium = projected_weekly_income × active_rate
        """
        return (projected_weekly_income * tier.active_rate).quantize(
            Decimal("0.01"), rounding=ROUND_HALF_UP
        )

    @staticmethod
    def calculate_payout_amount(projected_weekly_income: Decimal) -> Decimal:
        """
        Payout = 20% of projected weekly income.
        Defined in BASE_PAYOUT_PERCENTAGE constant.
        """
        return (
            projected_weekly_income * Decimal(str(BASE_PAYOUT_PERCENTAGE))
        ).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

    @staticmethod
    def is_front_load_period(worker_created_at: datetime) -> bool:
        """
        Front-loading applies during the first 30 days after worker registration.
        This builds the ₹55.5 Crore disaster-ready corpus.
        """
        return (datetime.utcnow() - worker_created_at).days < 30

    @staticmethod
    async def get_insurance_summary(
        db: AsyncSession,
        worker_id: uuid.UUID,
    ) -> Optional[Dict]:
        """
        Build a complete insurance summary for the worker dashboard.

        Returns all Phase 4 metrics:
          - Current tier and rates
          - Weekly premium amount
          - Payout potential
          - Policy status and validity
          - Corpus contribution context
        """
        worker = await WorkerRepository.get_by_id(db, worker_id)
        if not worker:
            return None

        policy = await PolicyRepository.get_active_by_worker(db, worker_id)

        # Determine front-load period
        created_at = worker.created_at or datetime.utcnow()
        front_load = PremiumService.is_front_load_period(created_at)

        # Classify tier
        tier = PremiumService.classify_tier(worker.weekly_rides_completed, front_load)

        # Calculate financials
        income = worker.projected_weekly_income or Decimal("0")
        weekly_premium = (
            PremiumService.calculate_weekly_premium(income, tier)
            if income > 0
            else Decimal("0")
        )
        payout_potential = (
            PremiumService.calculate_payout_amount(income)
            if income > 0
            else Decimal("0")
        )

        # Days remaining in front-load period
        days_since_join = (datetime.utcnow() - created_at).days
        front_load_days_remaining = max(0, 30 - days_since_join)

        return {
            "worker_id": str(worker_id),
            "tier": tier.to_dict(),
            "projected_weekly_income": float(income),
            "weekly_premium_amount": float(weekly_premium),
            "payout_potential": float(payout_potential),
            "wallet_balance": float(worker.wallet_balance),
            "weekly_rides_completed": worker.weekly_rides_completed,
            "policy": {
                "is_active": policy.is_active if policy else False,
                "premium_rate_percent": float(policy.premium_rate_percentage) if policy else 0.0,
                "valid_until": policy.valid_until.isoformat() if policy else None,
            },
            "front_load_period": {
                "is_active": front_load,
                "days_remaining": front_load_days_remaining,
                "purpose": "Building ₹55.5 Crore Disaster Ready corpus",
            },
            "coverage_summary": {
                "covers": "Loss of income during adverse weather events",
                "excludes": "Health, life, vehicle repair",
                "trigger": "Rain ≥ 5mm OR Wind ≥ 40 km/h OR Temp ≤ 5°C OR Temp ≥ 42°C",
                "payout_formula": "20% of projected weekly income",
            },
        }

    @staticmethod
    async def deduct_weekly_premium(
        db: AsyncSession,
        worker_id: uuid.UUID,
        is_front_load: bool = False,
    ) -> Tuple[bool, Decimal, str]:
        """
        Deduct weekly premium from worker's wallet and create a PREMIUM_PAYMENT transaction.

        Returns (success, amount_deducted, reason)
        """
        worker = await WorkerRepository.get_by_id(db, worker_id)
        if not worker:
            return False, Decimal("0"), "Worker not found"

        if not worker.projected_weekly_income:
            return False, Decimal("0"), "No projected weekly income set"

        tier = PremiumService.classify_tier(worker.weekly_rides_completed, is_front_load)
        premium = PremiumService.calculate_weekly_premium(
            worker.projected_weekly_income, tier
        )

        if worker.wallet_balance < premium:
            return False, Decimal("0"), f"Insufficient wallet balance (₹{worker.wallet_balance:.2f})"

        # Deduct from wallet (negative amount)
        worker.wallet_balance -= premium
        await db.commit()

        # Record transaction
        tx = TransactionCreate(
            worker_id=worker_id,
            amount=premium,
            type="PREMIUM_PAYMENT",
            reason=(
                f"Weekly premium — {tier.tier_name} "
                f"({'Front-load' if is_front_load else 'Standard'} "
                f"{tier.active_rate_percent:.0f}%)"
            ),
        )
        await TransactionRepository.create(db, tx)

        return True, premium, f"Premium of ₹{premium:.2f} deducted ({tier.tier_name})"

    @staticmethod
    async def update_weekly_rides(
        db: AsyncSession,
        worker_id: uuid.UUID,
        rides_delta: int,
    ) -> Tuple[bool, int, str]:
        """
        Increment weekly ride count and recalculate tier.
        Called after each completed delivery.
        """
        worker = await WorkerRepository.get_by_id(db, worker_id)
        if not worker:
            return False, 0, "Worker not found"

        worker.weekly_rides_completed += rides_delta
        await db.commit()

        new_tier = PremiumService.classify_tier(worker.weekly_rides_completed)
        return (
            True,
            worker.weekly_rides_completed,
            f"Rides updated to {worker.weekly_rides_completed} — {new_tier.tier_name}",
        )

    @staticmethod
    async def reset_weekly_cycle(
        db: AsyncSession,
        worker_id: uuid.UUID,
    ) -> bool:
        """
        Reset weekly ride counter and renew policy at end of each week.
        Called by a scheduled job (weekly cron).
        """
        worker = await WorkerRepository.get_by_id(db, worker_id)
        if not worker:
            return False

        worker.weekly_rides_completed = 0
        await db.commit()

        # Renew policy for next week
        front_load = PremiumService.is_front_load_period(worker.created_at or datetime.utcnow())
        tier = PremiumService.classify_tier(0, front_load)

        policy_data = PolicyCreate(
            worker_id=worker_id,
            premium_rate_percentage=tier.active_rate * 100,
            valid_until=datetime.utcnow() + timedelta(days=7),
        )
        await PolicyRepository.create(db, policy_data)
        return True
