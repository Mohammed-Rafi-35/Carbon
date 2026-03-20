import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../../core/network/api_client.dart';
import '../models/insurance_summary.dart';

/// Phase 4 — Insurance Repository
///
/// Handles all insurance math operations:
///   - Fetching the full insurance summary dashboard
///   - Incrementing weekly ride count
///   - Deducting weekly premium
class InsuranceRepository {
  final ApiClient _apiClient;

  InsuranceRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Fetch the complete insurance summary for the worker dashboard.
  Future<InsuranceSummary> getInsuranceSummary(String workerId) async {
    try {
      final endpoint = await ApiConfig.workerInsuranceSummary(workerId);
      final response = await _apiClient.get(endpoint);
      return InsuranceSummary.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) throw Exception('Worker not found');
      throw Exception('Failed to load insurance summary: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load insurance summary: $e');
    }
  }

  /// Increment weekly ride count after a completed delivery.
  Future<int> incrementRides(String workerId, {int rides = 1}) async {
    try {
      final endpoint = await ApiConfig.workerIncrementRides(workerId);
      final response = await _apiClient.post(
        '$endpoint?rides=$rides',
        data: {},
      );
      return response.data['weekly_rides_completed'] as int;
    } on DioException catch (e) {
      throw Exception('Failed to update rides: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update rides: $e');
    }
  }

  /// Deduct weekly premium from worker wallet.
  Future<double> deductPremium(String workerId,
      {bool frontLoad = false}) async {
    try {
      final endpoint = await ApiConfig.workerDeductPremium(workerId);
      final response = await _apiClient.post(
        '$endpoint?front_load=$frontLoad',
        data: {},
      );
      return (response.data['amount_deducted'] as num).toDouble();
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final detail = e.response?.data['detail'] ?? 'Premium deduction failed';
        throw Exception(detail);
      }
      throw Exception('Failed to deduct premium: ${e.message}');
    } catch (e) {
      throw Exception('Failed to deduct premium: $e');
    }
  }
}
