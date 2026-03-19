import 'package:equatable/equatable.dart';

/// Payout response from trigger endpoint
class Payout extends Equatable {
  final String id;
  final String workerId;
  final String orderId;
  final double amount;
  final String status;
  final String reason;
  final DateTime timestamp;
  final Map<String, bool>? securityChecks;

  const Payout({
    required this.id,
    required this.workerId,
    required this.orderId,
    required this.amount,
    required this.status,
    required this.reason,
    required this.timestamp,
    this.securityChecks,
  });

  factory Payout.fromJson(Map<String, dynamic> json) {
    return Payout(
      id: json['id'] as String? ?? json['transaction_id'] as String? ?? '',
      workerId: json['worker_id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      amount: json['amount'] != null
          ? (json['amount'] is String
              ? double.parse(json['amount'])
              : (json['amount'] as num).toDouble())
          : json['payout_amount'] != null
              ? (json['payout_amount'] is String
                  ? double.parse(json['payout_amount'])
                  : (json['payout_amount'] as num).toDouble())
              : 0.0,
      status: json['status'] as String? ?? (json['success'] == true ? 'approved' : 'rejected'),
      reason: json['reason'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      securityChecks: json['security_checks'] != null
          ? Map<String, bool>.from(json['security_checks'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'worker_id': workerId,
      'order_id': orderId,
      'amount': amount,
      'status': status,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
      if (securityChecks != null) 'security_checks': securityChecks,
    };
  }

  @override
  List<Object?> get props => [
        id,
        workerId,
        orderId,
        amount,
        status,
        reason,
        timestamp,
        securityChecks,
      ];
}

// Legacy classes for backward compatibility
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
