import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage wrapper for sensitive data
/// Uses flutter_secure_storage for encrypted storage
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Storage keys
  static const String _keyWorkerId = 'worker_id';
  static const String _keyPhone = 'phone';
  static const String _keyZone = 'zone';
  static const String _keyVehicleType = 'vehicle_type';

  /// Save worker credentials after login/register
  static Future<void> saveWorkerCredentials({
    required String workerId,
    required String phone,
    required String zone,
    required String vehicleType,
  }) async {
    await Future.wait([
      _storage.write(key: _keyWorkerId, value: workerId),
      _storage.write(key: _keyPhone, value: phone),
      _storage.write(key: _keyZone, value: zone),
      _storage.write(key: _keyVehicleType, value: vehicleType),
    ]);
  }

  /// Get stored worker ID
  static Future<String?> getWorkerId() async {
    return await _storage.read(key: _keyWorkerId);
  }

  /// Get stored phone number
  static Future<String?> getPhone() async {
    return await _storage.read(key: _keyPhone);
  }

  /// Get stored zone
  static Future<String?> getZone() async {
    return await _storage.read(key: _keyZone);
  }

  /// Get stored vehicle type
  static Future<String?> getVehicleType() async {
    return await _storage.read(key: _keyVehicleType);
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final workerId = await getWorkerId();
    return workerId != null && workerId.isNotEmpty;
  }

  /// Clear all stored credentials (logout)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Get all stored credentials
  static Future<Map<String, String?>> getAllCredentials() async {
    return {
      'workerId': await getWorkerId(),
      'phone': await getPhone(),
      'zone': await getZone(),
      'vehicleType': await getVehicleType(),
    };
  }
}
