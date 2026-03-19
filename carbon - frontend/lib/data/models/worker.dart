import 'package:equatable/equatable.dart';

class Worker extends Equatable {
  final String id;
  final String phone;
  final String zone;
  final String vehicleType;
  final double walletBalance;
  final int weeklyRidesCompleted;
  final double? projectedWeeklyIncome;

  const Worker({
    required this.id,
    required this.phone,
    required this.zone,
    required this.vehicleType,
    required this.walletBalance,
    required this.weeklyRidesCompleted,
    this.projectedWeeklyIncome,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id'] as String,
      phone: json['phone'] as String,
      zone: json['zone'] as String,
      vehicleType: json['vehicle_type'] as String,
      walletBalance: (json['wallet_balance'] is String)
          ? double.parse(json['wallet_balance'])
          : (json['wallet_balance'] as num).toDouble(),
      weeklyRidesCompleted: json['weekly_rides_completed'] as int,
      projectedWeeklyIncome: json['projected_weekly_income'] != null
          ? (json['projected_weekly_income'] is String)
              ? double.parse(json['projected_weekly_income'])
              : (json['projected_weekly_income'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'zone': zone,
      'vehicle_type': vehicleType,
      'wallet_balance': walletBalance,
      'weekly_rides_completed': weeklyRidesCompleted,
      'projected_weekly_income': projectedWeeklyIncome,
    };
  }

  Worker copyWith({
    String? id,
    String? phone,
    String? zone,
    String? vehicleType,
    double? walletBalance,
    int? weeklyRidesCompleted,
    double? projectedWeeklyIncome,
  }) {
    return Worker(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      zone: zone ?? this.zone,
      vehicleType: vehicleType ?? this.vehicleType,
      walletBalance: walletBalance ?? this.walletBalance,
      weeklyRidesCompleted: weeklyRidesCompleted ?? this.weeklyRidesCompleted,
      projectedWeeklyIncome: projectedWeeklyIncome ?? this.projectedWeeklyIncome,
    );
  }

  @override
  List<Object?> get props => [
        id,
        phone,
        zone,
        vehicleType,
        walletBalance,
        weeklyRidesCompleted,
        projectedWeeklyIncome,
      ];
}
