import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../../core/network/api_client.dart';
import '../models/policy.dart';

/// Policy repository — Phase 1 Data Persistence
///
/// Handles creation and retrieval of worker insurance policies.
/// A policy must exist before any payout can be triggered.
class PolicyRepository {
  final ApiClient _apiClient;

  PolicyRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Create a weekly insurance policy for a worker.
  ///
  /// Premium rate is determined by ride tier:
  ///   100+ rides/week → 5%
  ///   70–99 rides/week → 4%
  ///   < 70 rides/week → 3%
  Future<Policy> createPolicy({
    required String workerId,
    required double premiumRatePercentage,
    required DateTime validUntil,
  }) async {
    try {
      final endpoint = await ApiConfig.workerPolicy(workerId);
      final response = await _apiClient.post(
        endpoint,
        data: {
          'worker_id': workerId,
          'premium_rate_percentage': premiumRatePercentage.toStringAsFixed(2),
          'valid_until': validUntil.toIso8601String(),
        },
      );
      return Policy.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) throw Exception('Worker not found');
      if (e.response?.statusCode == 409) throw Exception('Policy already exists');
      throw Exception('Failed to create policy: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create policy: $e');
    }
  }

  /// Get the active policy for a worker.
  Future<Policy?> getActivePolicy(String workerId) async {
    try {
      final endpoint = await ApiConfig.workerPolicy(workerId);
      final response = await _apiClient.get(endpoint);
      return Policy.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception('Failed to fetch policy: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch policy: $e');
    }
  }
}
