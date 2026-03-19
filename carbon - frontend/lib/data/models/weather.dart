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
  final String thresholdReason;

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
    required this.thresholdReason,
  });

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
      thresholdReason: json['threshold_reason'] as String,
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
      ];
}
