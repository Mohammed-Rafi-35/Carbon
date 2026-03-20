import '../../config/api_config.dart';
import '../../core/network/api_client.dart';

class AdminRepository {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getDashboard(String adminKey) async {
    final url = '${await ApiConfig.getBasePath()}/admin/dashboard';
    final r = await _client.get(url, headers: {'X-Admin-Key': adminKey});
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getFraudQueue(String adminKey,
      {int limit = 50}) async {
    final url =
        '${await ApiConfig.getBasePath()}/admin/fraud-queue?limit=$limit';
    final r = await _client.get(url, headers: {'X-Admin-Key': adminKey});
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getDisruptionAnalytics(String adminKey,
      {int days = 7}) async {
    final url =
        '${await ApiConfig.getBasePath()}/admin/analytics/disruptions?days=$days';
    final r = await _client.get(url, headers: {'X-Admin-Key': adminKey});
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> listWorkers(String adminKey,
      {int limit = 100, int offset = 0}) async {
    final url =
        '${await ApiConfig.getBasePath()}/admin/workers?limit=$limit&offset=$offset';
    final r = await _client.get(url, headers: {'X-Admin-Key': adminKey});
    return r.data as Map<String, dynamic>;
  }

  Future<void> deactivateWorker(String adminKey, String workerId) async {
    final url =
        '${await ApiConfig.getBasePath()}/admin/workers/$workerId/deactivate';
    await _client.patch(url, headers: {'X-Admin-Key': adminKey});
  }

  Future<void> reactivateWorker(String adminKey, String workerId) async {
    final url =
        '${await ApiConfig.getBasePath()}/admin/workers/$workerId/reactivate';
    await _client.patch(url, headers: {'X-Admin-Key': adminKey});
  }

  Future<Map<String, dynamic>> getWorkerDataReport(
      String adminKey, String workerId) async {
    final url =
        '${await ApiConfig.getBasePath()}/admin/workers/$workerId/data-report';
    final r = await _client.get(url, headers: {'X-Admin-Key': adminKey});
    return r.data as Map<String, dynamic>;
  }
}
