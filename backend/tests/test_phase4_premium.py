"""
Phase 4 Tests — Revenue Model & Corpus Strategy

Tests the complete insurance math engine:
  - Tier classification (TIER_1/2/3 by ride count)
  - Front-loading rates (Month 1: 7/5/3%)
  - Standard rates (5/4/3%)
  - Weekly premium calculation
  - Payout amount calculation (20% of income)
  - Premium deduction from wallet
  - Insurance summary endpoint
  - Weekly cycle reset
"""
import pytest
from decimal import Decimal
from datetime import datetime, timedelta
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.db.session import get_db
from app.db.repository import WorkerRepository, PolicyRepository
from app.schemas.models import WorkerCreate, PolicyCreate
from app.services.premium_svc import PremiumService, PremiumTier
from app.core.constants import PREMIUM_TIERS, FRONT_LOAD_TIERS, BASE_PAYOUT_PERCENTAGE


class TestTierClassification:
    """Phase 4: Ride-based tier classification."""

    def test_tier1_100_rides(self):
        tier = PremiumService.classify_tier(100)
        assert tier.tier_name == "TIER_1"
        assert tier.standard_rate == Decimal("0.05")

    def test_tier1_150_rides(self):
        tier = PremiumService.classify_tier(150)
        assert tier.tier_name == "TIER_1"

    def test_tier2_70_rides(self):
        tier = PremiumService.classify_tier(70)
        assert tier.tier_name == "TIER_2"
        assert tier.standard_rate == Decimal("0.04")

    def test_tier2_99_rides(self):
        tier = PremiumService.classify_tier(99)
        assert tier.tier_name == "TIER_2"

    def test_tier3_below_70(self):
        tier = PremiumService.classify_tier(50)
        assert tier.tier_name == "TIER_3"
        assert tier.standard_rate == Decimal("0.03")

    def test_tier3_zero_rides(self):
        tier = PremiumService.classify_tier(0)
        assert tier.tier_name == "TIER_3"

    def test_tier_boundary_exactly_70(self):
        """70 rides is TIER_2, 69 is TIER_3."""
        assert PremiumService.classify_tier(70).tier_name == "TIER_2"
        assert PremiumService.classify_tier(69).tier_name == "TIER_3"

    def test_tier_boundary_exactly_100(self):
        """100 rides is TIER_1, 99 is TIER_2."""
        assert PremiumService.classify_tier(100).tier_name == "TIER_1"
        assert PremiumService.classify_tier(99).tier_name == "TIER_2"


class TestFrontLoadRates:
    """Phase 4: Front-loading corpus strategy rates."""

    def test_tier1_front_load_rate_7_percent(self):
        tier = PremiumService.classify_tier(100, is_front_load=True)
        assert tier.front_load_rate == Decimal("0.07")
        assert tier.active_rate == Decimal("0.07")
        assert tier.active_rate_percent == pytest.approx(7.0)

    def test_tier2_front_load_rate_5_percent(self):
        tier = PremiumService.classify_tier(80, is_front_load=True)
        assert tier.front_load_rate == Decimal("0.05")
        assert tier.active_rate == Decimal("0.05")

    def test_tier3_front_load_rate_3_percent(self):
        tier = PremiumService.classify_tier(50, is_front_load=True)
        assert tier.front_load_rate == Decimal("0.03")
        assert tier.active_rate == Decimal("0.03")

    def test_standard_rate_used_when_not_front_load(self):
        tier = PremiumService.classify_tier(100, is_front_load=False)
        assert tier.active_rate == Decimal("0.05")  # Standard, not 7%

    def test_front_load_period_detection_new_worker(self):
        """Worker registered today → front-load period active."""
        created_at = datetime.utcnow()
        assert PremiumService.is_front_load_period(created_at) is True

    def test_front_load_period_detection_old_worker(self):
        """Worker registered 31 days ago → front-load period over."""
        created_at = datetime.utcnow() - timedelta(days=31)
        assert PremiumService.is_front_load_period(created_at) is False

    def test_front_load_period_boundary_day_29(self):
        created_at = datetime.utcnow() - timedelta(days=29)
        assert PremiumService.is_front_load_period(created_at) is True

    def test_front_load_period_boundary_day_30(self):
        created_at = datetime.utcnow() - timedelta(days=30)
        assert PremiumService.is_front_load_period(created_at) is False


class TestPremiumCalculation:
    """Phase 4: Weekly premium and payout amount math."""

    def test_tier1_standard_premium_5000_income(self):
        """TIER_1 standard: 5% of ₹5000 = ₹250"""
        tier = PremiumService.classify_tier(100, is_front_load=False)
        premium = PremiumService.calculate_weekly_premium(Decimal("5000"), tier)
        assert premium == Decimal("250.00")

    def test_tier1_front_load_premium_5000_income(self):
        """TIER_1 front-load: 7% of ₹5000 = ₹350"""
        tier = PremiumService.classify_tier(100, is_front_load=True)
        premium = PremiumService.calculate_weekly_premium(Decimal("5000"), tier)
        assert premium == Decimal("350.00")

    def test_tier2_standard_premium_4000_income(self):
        """TIER_2 standard: 4% of ₹4000 = ₹160"""
        tier = PremiumService.classify_tier(80, is_front_load=False)
        premium = PremiumService.calculate_weekly_premium(Decimal("4000"), tier)
        assert premium == Decimal("160.00")

    def test_tier3_standard_premium_3000_income(self):
        """TIER_3 standard: 3% of ₹3000 = ₹90"""
        tier = PremiumService.classify_tier(50, is_front_load=False)
        premium = PremiumService.calculate_weekly_premium(Decimal("3000"), tier)
        assert premium == Decimal("90.00")

    def test_payout_amount_20_percent(self):
        """Payout = 20% of projected weekly income."""
        payout = PremiumService.calculate_payout_amount(Decimal("5000"))
        assert payout == Decimal("1000.00")

    def test_payout_amount_various_incomes(self):
        assert PremiumService.calculate_payout_amount(Decimal("3000")) == Decimal("600.00")
        assert PremiumService.calculate_payout_amount(Decimal("7500")) == Decimal("1500.00")
        assert PremiumService.calculate_payout_amount(Decimal("10000")) == Decimal("2000.00")

    def test_premium_rounding_half_up(self):
        """Verify ROUND_HALF_UP for financial precision."""
        tier = PremiumService.classify_tier(50, is_front_load=False)  # 3%
        # 3% of 3333.33 = 99.9999 → rounds to 100.00
        premium = PremiumService.calculate_weekly_premium(Decimal("3333.33"), tier)
        assert premium == Decimal("100.00")

    def test_base_payout_percentage_constant(self):
        """Verify the constant matches the document spec (20%)."""
        assert BASE_PAYOUT_PERCENTAGE == 0.20


class TestPremiumServiceDB:
    """Phase 4: Database-backed premium operations."""

    @pytest.mark.asyncio
    async def test_deduct_weekly_premium_success(self, test_db, created_worker):
        """Premium deduction reduces wallet and creates PREMIUM_PAYMENT transaction."""
        from app.db.repository import TransactionRepository

        # Fund the wallet first
        await WorkerRepository.update_wallet(test_db, created_worker.id, Decimal("500"))
        worker_before = await WorkerRepository.get_by_id(test_db, created_worker.id)
        balance_before = worker_before.wallet_balance

        success, amount, msg = await PremiumService.deduct_weekly_premium(
            test_db, created_worker.id, is_front_load=False
        )

        assert success is True
        assert amount > Decimal("0")

        worker_after = await WorkerRepository.get_by_id(test_db, created_worker.id)
        assert worker_after.wallet_balance == balance_before - amount

        # Verify transaction record
        txs = await TransactionRepository.get_by_worker(test_db, created_worker.id)
        premium_txs = [t for t in txs if t.type == "PREMIUM_PAYMENT"]
        assert len(premium_txs) == 1
        assert premium_txs[0].amount == amount

    @pytest.mark.asyncio
    async def test_deduct_premium_insufficient_balance(self, test_db):
        """Premium deduction fails when wallet balance is insufficient."""
        worker_data = WorkerCreate(
            name="Poor Worker",
            phone="+919111111111",
            password="testpass123",
            zone="Test-Zone",
            vehicle_type="bike",
            projected_weekly_income=Decimal("5000"),
        )
        worker = await WorkerRepository.create(test_db, worker_data)
        # Wallet starts at 0 — premium of ₹150 (3% of 5000) cannot be deducted

        success, amount, msg = await PremiumService.deduct_weekly_premium(
            test_db, worker.id, is_front_load=False
        )

        assert success is False
        assert "Insufficient" in msg

    @pytest.mark.asyncio
    async def test_update_weekly_rides(self, test_db, created_worker):
        """Ride count increments correctly and tier recalculates."""
        success, total, msg = await PremiumService.update_weekly_rides(
            test_db, created_worker.id, rides_delta=50
        )
        assert success is True
        assert total == 50

        success2, total2, msg2 = await PremiumService.update_weekly_rides(
            test_db, created_worker.id, rides_delta=25
        )
        assert total2 == 75
        assert "TIER_2" in msg2

    @pytest.mark.asyncio
    async def test_update_rides_crosses_tier1_boundary(self, test_db, created_worker):
        """Crossing 100 rides moves worker to TIER_1."""
        await PremiumService.update_weekly_rides(test_db, created_worker.id, 100)
        _, total, msg = await PremiumService.update_weekly_rides(
            test_db, created_worker.id, 0
        )
        assert "TIER_1" in msg

    @pytest.mark.asyncio
    async def test_get_insurance_summary(self, test_db, created_worker):
        """Insurance summary returns all required Phase 4 fields."""
        await PolicyRepository.create(test_db, PolicyCreate(
            worker_id=created_worker.id,
            premium_rate_percentage=Decimal("5.0"),
            valid_until=datetime.now() + timedelta(days=7),
        ))

        summary = await PremiumService.get_insurance_summary(test_db, created_worker.id)

        assert summary is not None
        assert "tier" in summary
        assert "weekly_premium_amount" in summary
        assert "payout_potential" in summary
        assert "policy" in summary
        assert "front_load_period" in summary
        assert "coverage_summary" in summary

        # Verify math: 20% of 5000 = 1000
        assert summary["payout_potential"] == pytest.approx(1000.0)
        assert summary["policy"]["is_active"] is True

    @pytest.mark.asyncio
    async def test_insurance_summary_no_policy(self, test_db, created_worker):
        """Summary still returns when no policy exists — policy.is_active = False."""
        summary = await PremiumService.get_insurance_summary(test_db, created_worker.id)
        assert summary["policy"]["is_active"] is False

    @pytest.mark.asyncio
    async def test_weekly_reset_clears_rides(self, test_db, created_worker):
        """Weekly reset zeroes ride count and creates new policy."""
        await PremiumService.update_weekly_rides(test_db, created_worker.id, 80)
        worker_mid = await WorkerRepository.get_by_id(test_db, created_worker.id)
        assert worker_mid.weekly_rides_completed == 80

        success = await PremiumService.reset_weekly_cycle(test_db, created_worker.id)
        assert success is True

        worker_after = await WorkerRepository.get_by_id(test_db, created_worker.id)
        assert worker_after.weekly_rides_completed == 0


class TestInsuranceSummaryEndpoint:
    """Phase 4: HTTP endpoint tests for insurance summary."""

    @pytest.mark.asyncio
    async def test_get_insurance_summary_endpoint(self, test_db, created_worker):
        """GET /workers/{id}/insurance-summary returns full Phase 4 data."""
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db

        await PolicyRepository.create(test_db, PolicyCreate(
            worker_id=created_worker.id,
            premium_rate_percentage=Decimal("5.0"),
            valid_until=datetime.now() + timedelta(days=7),
        ))

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.get(f"/api/v1/workers/{created_worker.id}/insurance-summary")

        assert response.status_code == 200
        data = response.json()
        assert data["payout_potential"] == pytest.approx(1000.0)
        assert "tier" in data
        assert data["coverage_summary"]["payout_formula"] == "20% of projected weekly income"
        app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_increment_rides_endpoint(self, test_db, created_worker):
        """POST /workers/{id}/rides/increment updates ride count."""
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post(
                f"/api/v1/workers/{created_worker.id}/rides/increment?rides=10"
            )

        assert response.status_code == 200
        assert response.json()["weekly_rides_completed"] == 10
        app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_premium_deduct_endpoint(self, test_db, created_worker):
        """POST /workers/{id}/premium/deduct deducts premium from wallet."""
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db

        # Fund wallet
        await WorkerRepository.update_wallet(test_db, created_worker.id, Decimal("1000"))

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post(
                f"/api/v1/workers/{created_worker.id}/premium/deduct"
            )

        assert response.status_code == 200
        assert response.json()["amount_deducted"] > 0
        app.dependency_overrides.clear()

    @pytest.mark.asyncio
    async def test_weekly_reset_endpoint(self, test_db, created_worker):
        """POST /workers/{id}/weekly-reset resets rides and renews policy."""
        from app.db.session import get_db
        app.dependency_overrides[get_db] = lambda: test_db

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            response = await client.post(
                f"/api/v1/workers/{created_worker.id}/weekly-reset"
            )

        assert response.status_code == 200
        assert "reset" in response.json()["message"].lower()
        app.dependency_overrides.clear()
