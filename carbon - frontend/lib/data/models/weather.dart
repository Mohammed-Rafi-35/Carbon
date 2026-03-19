import 'package:equatable/equatable.dart';

class Weather extends Equatable {
  final double temperatureCelsius;
  final double rainMm;
  final double humidityPercent;
  final double windSpeedKmh;
  final String zone;
  final double lat;
  final double lon;
  final String timestamp;
  final bool meetsThreshold;
  final String? thresholdReason;
  
  // Thresholds (default values matching backend)
  final double rainThreshold;
  final double windThreshold;
  final double tempThreshold;

  const Weather({
    required this.temperatureCelsius,
    required this.rainMm,
    required this.humidityPercent,
    required this.windSpeedKmh,
    required this.zone,
    required this.lat,
    required this.lon,
    required this.timestamp,
    required this.meetsThreshold,
    this.thresholdReason,
    this.rainThreshold = 5.0,
    this.windThreshold = 30.0,
    this.tempThreshold = 35.0,
  });

  // Convenience getters for UI
  double get tempC => temperatureCelsius;
  double get windKmh => windSpeedKmh;

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperatureCelsius: (json['temperature_celsius'] as num).toDouble(),
      rainMm: (json['rain_mm'] as num).toDouble(),
      humidityPercent: (json['humidity_percent'] as num).toDouble(),
      windSpeedKmh: (json['wind_speed_kmh'] as num).toDouble(),
      zone: json['zone'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      timestamp: json['timestamp'] as String,
      meetsThreshold: json['meets_threshold'] as bool,
      thresholdReason: json['threshold_reason'] as String?,
      rainThreshold: json['rain_threshold'] != null ? (json['rain_threshold'] as num).toDouble() : 5.0,
      windThreshold: json['wind_threshold'] != null ? (json['wind_threshold'] as num).toDouble() : 30.0,
      tempThreshold: json['temp_threshold'] != null ? (json['temp_threshold'] as num).toDouble() : 35.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature_celsius': temperatureCelsius,
      'rain_mm': rainMm,
      'humidity_percent': humidityPercent,
      'wind_speed_kmh': windSpeedKmh,
      'zone': zone,
      'lat': lat,
      'lon': lon,
      'timestamp': timestamp,
      'meets_threshold': meetsThreshold,
      'threshold_reason': thresholdReason,
    };
  }

  @override
  List<Object?> get props => [
        temperatureCelsius,
        rainMm,
        humidityPercent,
        windSpeedKmh,
        zone,
        lat,
        lon,
        timestamp,
        meetsThreshold,
        thresholdReason,
        rainThreshold,
        windThreshold,
        tempThreshold,
      ];
}
