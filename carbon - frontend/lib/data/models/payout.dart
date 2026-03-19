import 'package:equatable/equatable.dart';

class PayoutResponse extends Equatable {
  final bool success;
  final double? payoutAmount;
  final String? transactionId;
  final String reason;
  final Map<String, bool> securityChecks;
  final String timestamp;

  const PayoutResponse({
    required this.success,
    this.payoutAmount,
    this.transactionId,
    required this.reason,
    required this.securityChecks,
    required this.timestamp,
  });

  factory PayoutResponse.fromJson(Map<String, dynamic> json) {
    return PayoutResponse(
      success: json['success'] as bool,
      payoutAmount: json['payout_amount'] != null
          ? (json['payout_amount'] is String)
              ? double.parse(json['payout_amount'])
              : (json['payout_amount'] as num).toDouble()
          : null,
      transactionId: json['transaction_id'] as String?,
      reason: json['reason'] as String,
      securityChecks: Map<String, bool>.from(json['security_checks'] as Map),
      timestamp: json['timestamp'] as String,
    );
  }

  @override
  List<Object?> get props => [
        success,
        payoutAmount,
        transactionId,
        reason,
        securityChecks,
        timestamp,
      ];
}

class PayoutHistory extends Equatable {
  final String id;
  final double amount;
  final String reason;
  final String timestamp;

  const PayoutHistory({
    required this.id,
    required this.amount,
    required this.reason,
    required this.timestamp,
  });

  factory PayoutHistory.fromJson(Map<String, dynamic> json) {
    return PayoutHistory(
      id: json['id'] as String,
      amount: (json['amount'] is String)
          ? double.parse(json['amount'])
          : (json['amount'] as num).toDouble(),
      reason: json['reason'] as String,
      timestamp: json['timestamp'] as String,
    );
  }

  @override
  List<Object?> get props => [id, amount, reason, timestamp];
}

class SensorData extends Equatable {
  final double gpsSpeedKmh;
  final double accelerometerVariance;
  final double? gyroscopeVariance;
  final int? timestampDiffMs;

  const SensorData({
    required this.gpsSpeedKmh,
    required this.accelerometerVariance,
    this.gyroscopeVariance,
    this.timestampDiffMs,
  });

  Map<String, dynamic> toJson() {
    return {
      'gps_speed_kmh': gpsSpeedKmh,
      'accelerometer_variance': accelerometerVariance,
      if (gyroscopeVariance != null) 'gyroscope_variance': gyroscopeVariance,
      if (timestampDiffMs != null) 'timestamp_diff_ms': timestampDiffMs,
    };
  }

  @override
  List<Object?> get props => [
        gpsSpeedKmh,
        accelerometerVariance,
        gyroscopeVariance,
        timestampDiffMs,
      ];
}
