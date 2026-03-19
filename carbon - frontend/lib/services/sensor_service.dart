import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/models/sensor_data.dart';

/// Sensor fusion service for kinematic verification
/// Collects GPS speed and accelerometer variance for anti-fraud detection
class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  /// Check and request location permissions
  Future<bool> checkLocationPermission() async {
    final status = await Permission.location.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.location.request();
      return result.isGranted;
    }
    
    return false;
  }

  /// Get current GPS position
  Future<Position> getCurrentPosition() async {
    final hasPermission = await checkLocationPermission();
    
    if (!hasPermission) {
      throw Exception('Location permission denied');
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Calculate accelerometer variance over 3 seconds at 50Hz
  /// This is the core anti-fraud mechanism
  Future<double> calculateAccelerometerVariance() async {
    final List<double> magnitudes = [];
    final completer = Completer<double>();
    
    // Sample for 3 seconds at ~50Hz (150 samples)
    const samplingDuration = Duration(seconds: 3);
    const targetSamples = 150;
    
    StreamSubscription? subscription;
    final startTime = DateTime.now();
    
    subscription = accelerometerEventStream().listen((event) {
      // Calculate magnitude: sqrt(x^2 + y^2 + z^2)
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      magnitudes.add(magnitude);
      
      // Check if we've collected enough samples or time elapsed
      final elapsed = DateTime.now().difference(startTime);
      if (magnitudes.length >= targetSamples || elapsed >= samplingDuration) {
        subscription?.cancel();
        
        // Calculate variance
        if (magnitudes.isEmpty) {
          completer.complete(0.0);
        } else {
          final variance = _calculateVariance(magnitudes);
          completer.complete(variance);
        }
      }
    });
    
    // Timeout after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        subscription?.cancel();
        if (magnitudes.isEmpty) {
          completer.complete(0.0);
        } else {
          final variance = _calculateVariance(magnitudes);
          completer.complete(variance);
        }
      }
    });
    
    return completer.future;
  }

  /// Calculate variance from list of values
  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    // Calculate mean
    final mean = values.reduce((a, b) => a + b) / values.length;
    
    // Calculate variance: average of squared differences from mean
    final squaredDiffs = values.map((value) => pow(value - mean, 2));
    final variance = squaredDiffs.reduce((a, b) => a + b) / values.length;
    
    return variance;
  }

  /// Collect complete sensor data for payout trigger
  Future<SensorData> collectSensorData() async {
    // Get GPS position and speed
    final position = await getCurrentPosition();
    
    // Convert m/s to km/h
    final speedKmh = (position.speed * 3.6).clamp(0.0, 200.0);
    
    // Calculate accelerometer variance
    final variance = await calculateAccelerometerVariance();
    
    return SensorData(
      gpsSpeedKmh: speedKmh,
      accelerometerVariance: variance,
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
    );
  }

  /// Quick GPS check without accelerometer (for order reception)
  Future<Map<String, double>> getQuickLocation() async {
    final position = await getCurrentPosition();
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
    };
  }

  /// Stream GPS position updates
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }
}
