import 'package:equatable/equatable.dart';
import 'weather.dart';

/// Order model with weather synthesis
class Order extends Equatable {
  final String id;
  final String workerId;
  final double pickupLat;
  final double pickupLon;
  final double? dropoffLat;
  final double? dropoffLon;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Weather? weather;

  const Order({
    required this.id,
    required this.workerId,
    required this.pickupLat,
    required this.pickupLon,
    this.dropoffLat,
    this.dropoffLon,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.weather,
  });

  /// Create from JSON
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      workerId: json['worker_id'] as String,
      pickupLat: (json['pickup_lat'] as num).toDouble(),
      pickupLon: (json['pickup_lon'] as num).toDouble(),
      dropoffLat: json['dropoff_lat'] != null 
          ? (json['dropoff_lat'] as num).toDouble() 
          : null,
      dropoffLon: json['dropoff_lon'] != null 
          ? (json['dropoff_lon'] as num).toDouble() 
          : null,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String) 
          : null,
      weather: json['weather'] != null 
          ? Weather.fromJson(json['weather'] as Map<String, dynamic>) 
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'worker_id': workerId,
      'pickup_lat': pickupLat,
      'pickup_lon': pickupLon,
      'dropoff_lat': dropoffLat,
      'dropoff_lon': dropoffLon,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'weather': weather?.toJson(),
    };
  }

  /// Copy with
  Order copyWith({
    String? id,
    String? workerId,
    double? pickupLat,
    double? pickupLon,
    double? dropoffLat,
    double? dropoffLon,
    String? status,
    DateTime? createdAt,
    DateTime? completedAt,
    Weather? weather,
  }) {
    return Order(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLon: pickupLon ?? this.pickupLon,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLon: dropoffLon ?? this.dropoffLon,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      weather: weather ?? this.weather,
    );
  }

  /// Check if order is active
  bool get isActive => status == 'active' || status == 'in_progress';

  /// Check if order is completed
  bool get isCompleted => status == 'completed';

  /// Check if weather meets threshold
  bool get meetsWeatherThreshold => weather?.meetsThreshold ?? false;

  @override
  List<Object?> get props => [
        id,
        workerId,
        pickupLat,
        pickupLon,
        dropoffLat,
        dropoffLon,
        status,
        createdAt,
        completedAt,
        weather,
      ];
}
