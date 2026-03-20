import 'package:equatable/equatable.dart';

/// Insurance policy model — Phase 1 Data Persistence
class Policy extends Equatable {
  final String id;
  final String workerId;
  final bool isActive;
  final double premiumRatePercentage;
  final DateTime validUntil;
  final DateTime? createdAt;

  const Policy({
    required this.id,
    required this.workerId,
    required this.isActive,
    required this.premiumRatePercentage,
    required this.validUntil,
    this.createdAt,
  });

  factory Policy.fromJson(Map<String, dynamic> json) {
    return Policy(
      id: json['id'] as String,
      workerId: json['worker_id'] as String,
      isActive: json['is_active'] as bool,
      premiumRatePercentage: json['premium_rate_percentage'] is String
          ? double.parse(json['premium_rate_percentage'])
          : (json['premium_rate_percentage'] as num).toDouble(),
      validUntil: DateTime.parse(json['valid_until'] as String),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'worker_id': workerId,
        'is_active': isActive,
        'premium_rate_percentage': premiumRatePercentage,
        'valid_until': validUntil.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, workerId, isActive, premiumRatePercentage, validUntil];
}
