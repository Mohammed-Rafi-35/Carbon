import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../../core/network/api_client.dart';
import '../models/worker.dart';
import 'policy_repository.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final PolicyRepository _policyRepository;

  AuthRepository({ApiClient? apiClient, PolicyRepository? policyRepository})
      : _apiClient = apiClient ?? ApiClient(),
        _policyRepository = policyRepository ?? PolicyRepository();

  Future<Worker> register({
    required String name,
    required String phone,
    required String password,
    required String zone,
    required String vehicleType,
    double? projectedWeeklyIncome,
  }) async {
    try {
      final endpoint = await ApiConfig.workerRegister;
      final response = await _apiClient.post(endpoint, data: {
        'name': name,
        'phone': phone,
        'password': password,
        'zone': zone,
        'vehicle_type': vehicleType,
        'projected_weekly_income': projectedWeeklyIncome,
      }..removeWhere((_, v) => v == null));
      final worker = Worker.fromJson(response.data as Map<String, dynamic>);

      // Auto-create a weekly policy after registration
      // Phase 4 tier: < 70 rides → 3% (default for new workers)
      await _createInitialPolicy(worker.id);

      return worker;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('An account with this phone number already exists.');
      }
      throw Exception(_classifyNetworkError(e));
    } catch (e) {
      if (e.toString().contains('already exists')) rethrow;
      throw Exception('Registration failed: $e');
    }
  }

  Future<Worker> login({
    required String phone,
    required String password,
  }) async {
    try {
      final endpoint = await ApiConfig.workerLogin;
      final response = await _apiClient.post(endpoint, data: {
        'phone': phone,
        'password': password,
      });
      return Worker.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid phone number or password.');
      }
      if (e.response?.statusCode == 403) {
        throw Exception('Your account has been deactivated. Contact support.');
      }
      throw Exception(_classifyNetworkError(e));
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<Worker> getWorkerById(String workerId) async {
    try {
      final endpoint = await ApiConfig.workerById(workerId);
      final response = await _apiClient.get(endpoint);
      return Worker.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) throw Exception('Worker not found.');
      throw Exception(_classifyNetworkError(e));
    } catch (e) {
      throw Exception('Failed to fetch worker: $e');
    }
  }

  /// Create initial weekly policy for new worker.
  /// Uses 3% rate (Tier 3: < 70 rides) as default for new registrations.
  Future<void> _createInitialPolicy(String workerId) async {
    try {
      await _policyRepository.createPolicy(
        workerId: workerId,
        premiumRatePercentage: 3.0,
        validUntil: DateTime.now().add(const Duration(days: 7)),
      );
    } catch (_) {
      // Policy creation failure should not block registration
    }
  }

  String _classifyNetworkError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Server is not responding. Please check your connection or server URL.';
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. Make sure the server is running and the URL is correct.';
      case DioExceptionType.unknown:
        if (e.message?.contains('SocketException') ?? false) {
          return 'Cannot reach the server. Make sure the server is running and the URL is correct.';
        }
        return 'Connection failed. Please try again.';
      default:
        return 'Server error. Please try again later.';
    }
  }
}
