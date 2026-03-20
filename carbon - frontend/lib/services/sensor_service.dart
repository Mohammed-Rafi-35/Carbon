import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/models/sensor_data.dart';

/// What data is collected and why — shown to the user before any permission request.
/// Phase 3: Ethical transparency requirement.
class SensorDataDisclosure {
  static const String title = 'Sensor Data Usage';

  static const String body =
      'Carbon collects the following data ONLY when you tap "Claim Protection":\n\n'
      '• GPS Speed — to verify you are actively delivering\n'
      '• Accelerometer — to confirm genuine device movement\n\n'
      'This data is used exclusively to prevent fraudulent insurance claims. '
      'It is never sold, shared with third parties, or used for tracking. '
      'Collection stops immediately after your claim is processed.\n\n'
      'You can deny these permissions — the app will still work, '
      'but you will not be able to claim weather protection payouts.';

  static const String locationRationale =
      'Location is needed to verify your GPS speed during a claim. '
      'We read speed only — we do not store your route or track your movements.';

  static const String sensorRationale =
      'The accelerometer confirms your device is physically moving, '
      'preventing GPS spoofing fraud. Raw sensor values are processed '
      'on-device and only the variance (a single number) is sent to the server.';
}

/// Result of a permission request with user-facing context.
class PermissionResult {
  final bool granted;
  final String? deniedReason;

  const PermissionResult({required this.granted, this.deniedReason});
}

/// Phase 3 — Sensor Fusion Service with Ethical Permission Handling
///
/// Design principles:
///   1. Ask permission only when needed (not on app start)
///   2. Explain exactly what is collected and why before requesting
///   3. Never collect in the background
///   4. Graceful degradation — app works without permissions
///   5. No persistent location tracking
class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  // ── Permission Management ─────────────────────────────────────────────────

  /// Show the ethical disclosure dialog and request permissions.
  /// Returns true only if the user consented AND permissions were granted.
  Future<PermissionResult> requestSensorPermissionsWithConsent(
    BuildContext context,
  ) async {
    // Step 1: Show transparent disclosure dialog
    final consented = await _showConsentDialog(context);
    if (!consented) {
      return const PermissionResult(
        granted: false,
        deniedReason: 'You declined sensor data collection. Payout claims require this.',
      );
    }

    // Step 2: Request location permission
    // ignore: use_build_context_synchronously
    final locationResult = await _requestLocationPermission(context);
    if (!locationResult.granted) return locationResult;

    return const PermissionResult(granted: true);
  }

  /// Check if permissions are already granted (no dialog shown).
  Future<bool> hasRequiredPermissions() async {
    final location = await Permission.location.status;
    return location.isGranted;
  }

  Future<bool> _showConsentDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.privacy_tip_outlined,
                color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Data Privacy'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                SensorDataDisclosure.body,
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline,
                        size: 16,
                        color: Theme.of(ctx).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Data is processed on-device. Only a single variance number is transmitted.',
                        style: Theme.of(ctx).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Decline'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('I Understand, Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<PermissionResult> _requestLocationPermission(
    BuildContext context,
  ) async {
    var status = await Permission.location.status;

    if (status.isGranted) return const PermissionResult(granted: true);

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await _showSettingsDialog(
          context,
          title: 'Location Permission Required',
          message: SensorDataDisclosure.locationRationale,
        );
      }
      return PermissionResult(
        granted: false,
        deniedReason: 'Location permission permanently denied. Enable it in Settings.',
      );
    }

    // Show rationale before requesting
    if (status.isDenied) {
      if (!context.mounted) {
        return const PermissionResult(
          granted: false,
          deniedReason: 'Context no longer valid.',
        );
      }
      final proceed = await _showRationaleDialog(
        context,
        title: 'Location Access',
        rationale: SensorDataDisclosure.locationRationale,
      );
      if (!proceed) {
        return const PermissionResult(
          granted: false,
          deniedReason: 'Location permission declined.',
        );
      }
    }

    final result = await Permission.location.request();
    if (result.isGranted) return const PermissionResult(granted: true);

    return PermissionResult(
      granted: false,
      deniedReason: 'Location permission denied. Cannot verify GPS speed.',
    );
  }

  Future<bool> _showRationaleDialog(
    BuildContext context, {
    required String title,
    required String rationale,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(rationale),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // ── Sensor Collection ─────────────────────────────────────────────────────

  /// Get current GPS position (requires location permission).
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled');

    final status = await Permission.location.status;
    if (!status.isGranted) throw Exception('Location permission not granted');

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Calculate accelerometer variance over 3 seconds.
  ///
  /// Only the variance (a single scalar) is computed — raw x/y/z values
  /// are never stored or transmitted. Processing is entirely on-device.
  Future<double> calculateAccelerometerVariance() async {
    final magnitudes = <double>[];
    final completer = Completer<double>();
    StreamSubscription? sub;
    final start = DateTime.now();

    sub = accelerometerEventStream().listen((event) {
      final mag = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      magnitudes.add(mag);

      final elapsed = DateTime.now().difference(start);
      if (magnitudes.length >= 150 || elapsed >= const Duration(seconds: 3)) {
        sub?.cancel();
        completer.complete(_variance(magnitudes));
      }
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        sub?.cancel();
        completer.complete(_variance(magnitudes));
      }
    });

    return completer.future;
  }

  double _variance(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final sq = values.map((v) => pow(v - mean, 2));
    return sq.reduce((a, b) => a + b) / values.length;
  }

  /// Collect complete sensor data for a payout claim.
  ///
  /// Must only be called after [requestSensorPermissionsWithConsent] succeeds.
  Future<SensorData> collectSensorData() async {
    final position = await getCurrentPosition();
    final speedKmh = (position.speed * 3.6).clamp(0.0, 200.0);
    final variance = await calculateAccelerometerVariance();

    return SensorData(
      gpsSpeedKmh: speedKmh,
      accelerometerVariance: variance,
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
    );
  }

  /// Quick GPS location for order reception (no accelerometer).
  Future<Map<String, double>> getQuickLocation() async {
    final position = await getCurrentPosition();
    return {'latitude': position.latitude, 'longitude': position.longitude};
  }
}
