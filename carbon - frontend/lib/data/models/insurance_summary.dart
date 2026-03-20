import 'package:equatable/equatable.dart';

/// Phase 4 — Insurance Summary Model
///
/// Mirrors the backend PremiumService.get_insurance_summary() response.
class InsuranceSummary extends Equatable {
  final String workerId;
  final PremiumTierInfo tier;
  final double projectedWeeklyIncome;
  final double weeklyPremiumAmount;
  final double payoutPotential;
  final double walletBalance;
  final int weeklyRidesCompleted;
  final PolicyInfo policy;
  final FrontLoadInfo frontLoadPeriod;
  final CoverageSummary coverageSummary;

  const InsuranceSummary({
    required this.workerId,
    required this.tier,
    required this.projectedWeeklyIncome,
    required this.weeklyPremiumAmount,
    required this.payoutPotential,
    required this.walletBalance,
    required this.weeklyRidesCompleted,
    required this.policy,
    required this.frontLoadPeriod,
    required this.coverageSummary,
  });

  factory InsuranceSummary.fromJson(Map<String, dynamic> json) {
    return InsuranceSummary(
      workerId: json['worker_id'] as String,
      tier: PremiumTierInfo.fromJson(json['tier'] as Map<String, dynamic>),
      projectedWeeklyIncome: (json['projected_weekly_income'] as num).toDouble(),
      weeklyPremiumAmount: (json['weekly_premium_amount'] as num).toDouble(),
      payoutPotential: (json['payout_potential'] as num).toDouble(),
      walletBalance: (json['wallet_balance'] as num).toDouble(),
      weeklyRidesCompleted: json['weekly_rides_completed'] as int,
      policy: PolicyInfo.fromJson(json['policy'] as Map<String, dynamic>),
      frontLoadPeriod: FrontLoadInfo.fromJson(
          json['front_load_period'] as Map<String, dynamic>),
      coverageSummary: CoverageSummary.fromJson(
          json['coverage_summary'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [
        workerId, tier, projectedWeeklyIncome, weeklyPremiumAmount,
        payoutPotential, walletBalance, weeklyRidesCompleted,
      ];
}

class PremiumTierInfo extends Equatable {
  final String tierName;
  final int weeklyRides;
  final double standardRatePercent;
  final double frontLoadRatePercent;
  final double activeRatePercent;
  final bool isFrontLoadPeriod;

  const PremiumTierInfo({
    required this.tierName,
    required this.weeklyRides,
    required this.standardRatePercent,
    required this.frontLoadRatePercent,
    required this.activeRatePercent,
    required this.isFrontLoadPeriod,
  });

  factory PremiumTierInfo.fromJson(Map<String, dynamic> json) {
    return PremiumTierInfo(
      tierName: json['tier_name'] as String,
      weeklyRides: json['weekly_rides'] as int,
      standardRatePercent: (json['standard_rate_percent'] as num).toDouble(),
      frontLoadRatePercent: (json['front_load_rate_percent'] as num).toDouble(),
      activeRatePercent: (json['active_rate_percent'] as num).toDouble(),
      isFrontLoadPeriod: json['is_front_load_period'] as bool,
    );
  }

  String get displayName {
    switch (tierName) {
      case 'TIER_1': return 'Tier 1 — High Activity';
      case 'TIER_2': return 'Tier 2 — Medium Activity';
      default:       return 'Tier 3 — Standard';
    }
  }

  String get ridesRequirement {
    switch (tierName) {
      case 'TIER_1': return '100+ rides/week';
      case 'TIER_2': return '70–99 rides/week';
      default:       return '< 70 rides/week';
    }
  }

  @override
  List<Object?> get props => [tierName, weeklyRides, activeRatePercent];
}

class PolicyInfo extends Equatable {
  final bool isActive;
  final double premiumRatePercent;
  final DateTime? validUntil;

  const PolicyInfo({
    required this.isActive,
    required this.premiumRatePercent,
    this.validUntil,
  });

  factory PolicyInfo.fromJson(Map<String, dynamic> json) {
    return PolicyInfo(
      isActive: json['is_active'] as bool,
      premiumRatePercent: (json['premium_rate_percent'] as num).toDouble(),
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [isActive, premiumRatePercent, validUntil];
}

class FrontLoadInfo extends Equatable {
  final bool isActive;
  final int daysRemaining;
  final String purpose;

  const FrontLoadInfo({
    required this.isActive,
    required this.daysRemaining,
    required this.purpose,
  });

  factory FrontLoadInfo.fromJson(Map<String, dynamic> json) {
    return FrontLoadInfo(
      isActive: json['is_active'] as bool,
      daysRemaining: json['days_remaining'] as int,
      purpose: json['purpose'] as String,
    );
  }

  @override
  List<Object?> get props => [isActive, daysRemaining];
}

class CoverageSummary extends Equatable {
  final String covers;
  final String excludes;
  final String trigger;
  final String payoutFormula;

  const CoverageSummary({
    required this.covers,
    required this.excludes,
    required this.trigger,
    required this.payoutFormula,
  });

  factory CoverageSummary.fromJson(Map<String, dynamic> json) {
    return CoverageSummary(
      covers: json['covers'] as String,
      excludes: json['excludes'] as String,
      trigger: json['trigger'] as String,
      payoutFormula: json['payout_formula'] as String,
    );
  }

  @override
  List<Object?> get props => [covers, excludes, trigger, payoutFormula];
}
