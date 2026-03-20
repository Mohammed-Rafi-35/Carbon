import 'package:equatable/equatable.dart';
import 'weather.dart';

/// Order model — matches backend OrderResponse schema
class Order extends Equatable {
  final String id;
  final String workerId;
  final double pickupLat;
  final double pickupLon;
  final double dropoffLat;
  final double dropoffLon;
  final String status;
  final DateTime createdAt;
  final Weather? weather;

  const Order({
    required this.id,
    required this.workerId,
    required this.pickupLat,
    required this.pickupLon,
    required this.dropoffLat,
    required this.dropoffLon,
    required this.status,
    required this.createdAt,
    this.weather,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      workerId: json['worker_id'] as String,
      pickupLat: (json['pickup_lat'] as num).toDouble(),
      pickupLon: (json['pickup_lon'] as num).toDouble(),
      dropoffLat: (json['dropoff_lat'] as num).toDouble(),
      dropoffLon: (json['dropoff_lon'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      weather: json['weather'] != null
          ? Weather.fromJson(json['weather'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'worker_id': workerId,
        'pickup_lat': pickupLat,
        'pickup_lon': pickupLon,
        'dropoff_lat': dropoffLat,
        'dropoff_lon': dropoffLon,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'weather': weather?.toJson(),
      };

  Order copyWith({
    String? id,
    String? workerId,
    double? pickupLat,
    double? pickupLon,
    double? dropoffLat,
    double? dropoffLon,
    String? status,
    DateTime? createdAt,
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
      weather: weather ?? this.weather,
    );
  }

  bool get isActive => status == 'active' || status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get meetsWeatherThreshold => weather?.meetsThreshold ?? false;

  @override
  List<Object?> get props => [
        id, workerId, pickupLat, pickupLon, dropoffLat, dropoffLon,
        status, createdAt, weather,
      ];
}
