import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyWorkerId = 'worker_id';
  static const _keyName = 'name';
  static const _keyPhone = 'phone';
  static const _keyZone = 'zone';
  static const _keyVehicleType = 'vehicle_type';

  static Future<void> saveWorkerCredentials({
    required String workerId,
    required String name,
    required String phone,
    required String zone,
    required String vehicleType,
  }) async {
    await Future.wait([
      _storage.write(key: _keyWorkerId, value: workerId),
      _storage.write(key: _keyName, value: name),
      _storage.write(key: _keyPhone, value: phone),
      _storage.write(key: _keyZone, value: zone),
      _storage.write(key: _keyVehicleType, value: vehicleType),
    ]);
  }

  static Future<String?> getWorkerId() => _storage.read(key: _keyWorkerId);
  static Future<String?> getName() => _storage.read(key: _keyName);
  static Future<String?> getPhone() => _storage.read(key: _keyPhone);

  static Future<bool> isLoggedIn() async {
    final id = await getWorkerId();
    return id != null && id.isNotEmpty;
  }

  static Future<void> clearAll() => _storage.deleteAll();
}
