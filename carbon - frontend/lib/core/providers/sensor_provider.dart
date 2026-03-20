import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/sensor_data.dart';
import '../../services/sensor_service.dart';

final sensorServiceProvider = Provider<SensorService>((ref) => SensorService());

class SensorDataState {
  final SensorData? data;
  final bool isCollecting;
  final String? error;
  final bool permissionDenied;

  const SensorDataState({
    this.data,
    this.isCollecting = false,
    this.error,
    this.permissionDenied = false,
  });

  SensorDataState copyWith({
    SensorData? data,
    bool? isCollecting,
    String? error,
    bool? permissionDenied,
  }) {
    return SensorDataState(
      data: data ?? this.data,
      isCollecting: isCollecting ?? this.isCollecting,
      error: error,
      permissionDenied: permissionDenied ?? this.permissionDenied,
    );
  }
}

class SensorDataNotifier extends StateNotifier<SensorDataState> {
  final SensorService _sensorService;

  SensorDataNotifier(this._sensorService) : super(const SensorDataState());

  /// Collect sensor data with ethical consent flow.
  ///
  /// [context] is required to show the transparent permission dialog.
  /// Returns null if permission was denied or collection failed.
  Future<SensorData?> collectSensorData(BuildContext context) async {
    state = state.copyWith(isCollecting: true, error: null, permissionDenied: false);

    try {
      // Check if permissions already granted — skip dialog if so
      final alreadyGranted = await _sensorService.hasRequiredPermissions();

      if (!alreadyGranted) {
        if (!context.mounted) return null;
        final permResult =
            await _sensorService.requestSensorPermissionsWithConsent(context);

        if (!permResult.granted) {
          state = state.copyWith(
            isCollecting: false,
            permissionDenied: true,
            error: permResult.deniedReason,
          );
          return null;
        }
      }

      final sensorData = await _sensorService.collectSensorData();

      if (!sensorData.passesLocalValidation()) {
        state = state.copyWith(
          isCollecting: false,
          error: 'Sensor data failed validation. Please ensure you are actively delivering.',
        );
        return null;
      }

      state = state.copyWith(data: sensorData, isCollecting: false);
      return sensorData;
    } catch (e) {
      state = state.copyWith(isCollecting: false, error: e.toString());
      return null;
    }
  }

  /// Quick location for order reception — no consent dialog needed
  /// (location permission is requested inline by Geolocator).
  Future<Map<String, double>?> getQuickLocation() async {
    try {
      return await _sensorService.getQuickLocation();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final sensorDataProvider =
    StateNotifierProvider<SensorDataNotifier, SensorDataState>((ref) {
  return SensorDataNotifier(ref.watch(sensorServiceProvider));
});
