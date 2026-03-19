import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/sensor_data.dart';
import '../../services/sensor_service.dart';

/// Sensor service provider
final sensorServiceProvider = Provider<SensorService>((ref) {
  return SensorService();
});

/// Sensor data state
class SensorDataState {
  final SensorData? data;
  final bool isCollecting;
  final String? error;

  const SensorDataState({
    this.data,
    this.isCollecting = false,
    this.error,
  });

  SensorDataState copyWith({
    SensorData? data,
    bool? isCollecting,
    String? error,
  }) {
    return SensorDataState(
      data: data ?? this.data,
      isCollecting: isCollecting ?? this.isCollecting,
      error: error,
    );
  }
}

/// Sensor data notifier
class SensorDataNotifier extends StateNotifier<SensorDataState> {
  final SensorService _sensorService;

  SensorDataNotifier(this._sensorService) : super(const SensorDataState());

  /// Collect sensor data
  Future<SensorData?> collectSensorData() async {
    state = state.copyWith(isCollecting: true, error: null);

    try {
      final sensorData = await _sensorService.collectSensorData();
      
      // Validate locally
      if (!sensorData.passesLocalValidation()) {
        state = state.copyWith(
          isCollecting: false,
          error: 'Sensor data failed local validation. Please ensure you are moving naturally.',
        );
        return null;
      }

      state = state.copyWith(
        data: sensorData,
        isCollecting: false,
      );

      return sensorData;
    } catch (e) {
      state = state.copyWith(
        isCollecting: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Get quick location (without accelerometer)
  Future<Map<String, double>?> getQuickLocation() async {
    try {
      return await _sensorService.getQuickLocation();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Check location permission
  Future<bool> checkLocationPermission() async {
    return await _sensorService.checkLocationPermission();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Sensor data provider
final sensorDataProvider = StateNotifierProvider<SensorDataNotifier, SensorDataState>((ref) {
  final sensorService = ref.watch(sensorServiceProvider);
  return SensorDataNotifier(sensorService);
});
