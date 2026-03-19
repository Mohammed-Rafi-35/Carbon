import 'package:equatable/equatable.dart';

/// Sensor data model for kinematic verification
class SensorData extends Equatable {
  final double gpsSpeedKmh;
  final double accelerometerVariance;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const SensorData({
    required this.gpsSpeedKmh,
    required this.accelerometerVariance,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  /// Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'gps_speed_kmh': gpsSpeedKmh,
      'accelerometer_variance': accelerometerVariance,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      gpsSpeedKmh: (json['gps_speed_kmh'] as num).toDouble(),
      accelerometerVariance: (json['accelerometer_variance'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Check if sensor data passes local sanity checks
  bool passesLocalValidation() {
    // Speed should be reasonable (< 120 km/h for delivery workers)
    if (gpsSpeedKmh > 120) return false;
    
    // If moving (> 10 km/h), variance should be > 0.1
    if (gpsSpeedKmh > 10 && accelerometerVariance < 0.1) return false;
    
    // Variance should be positive
    if (accelerometerVariance < 0) return false;
    
    return true;
  }

  @override
  List<Object?> get props => [
        gpsSpeedKmh,
        accelerometerVariance,
        latitude,
        longitude,
        timestamp,
      ];
}
