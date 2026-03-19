import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../../core/network/api_client.dart';
import '../models/worker.dart';

/// Authentication repository
class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Register new worker
  Future<Worker> register({
    required String phone,
    required String zone,
    required String vehicleType,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.workerRegister,
        data: {
          'phone': phone,
          'zone': zone,
          'vehicle_type': vehicleType,
        },
      );

      return Worker.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw Exception('Worker with this phone already exists');
      }
      throw Exception('Registration failed: ${e.message}');
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Login with phone number
  Future<Worker> login(String phone) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.workerByPhone(phone),
      );

      return Worker.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Worker not found. Please register first.');
      }
      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Get worker by ID
  Future<Worker> getWorkerById(String workerId) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.workerById(workerId),
      );

      return Worker.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Worker not found');
      }
      throw Exception('Failed to fetch worker: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch worker: $e');
    }
  }
}
