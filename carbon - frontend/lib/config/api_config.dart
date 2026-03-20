import 'package:shared_preferences/shared_preferences.dart';

/// API Configuration
/// Centralized endpoint management for easy deployment changes
class ApiConfig {
  // Default Base URLs
  static const String defaultEmulatorUrl = 'http://10.0.2.2:8000';
  static const String defaultLocalhostUrl = 'http://localhost:8000';
  
  // Storage key for custom URL
  static const String _customUrlKey = 'custom_base_url';
  
  // API Version
  static const String apiVersion = '/api/v1';
  
  // Cached custom URL
  static String? _cachedCustomUrl;
  
  // Get current base URL (checks for override first)
  static Future<String> getBaseUrl() async {
    if (_cachedCustomUrl != null) return _cachedCustomUrl!;
    
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString(_customUrlKey);
    
    if (customUrl != null && customUrl.isNotEmpty) {
      _cachedCustomUrl = customUrl;
      return customUrl;
    }
    
    return defaultEmulatorUrl;
  }
  
  // Set custom base URL
  static Future<void> setCustomBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customUrlKey, url);
    _cachedCustomUrl = url;
  }
  
  // Clear custom URL (revert to default)
  static Future<void> clearCustomBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customUrlKey);
    _cachedCustomUrl = null;
  }
  
  // Get custom URL if set (for display purposes)
  static Future<String?> getCustomBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customUrlKey);
  }
  
  // Full base path
  static Future<String> getBasePath() async {
    final baseUrl = await getBaseUrl();
    return '$baseUrl$apiVersion';
  }
  
  // Worker Endpoints
  static Future<String> get workerRegister async => '${await getBasePath()}/workers/register';
  static Future<String> get workerLogin async => '${await getBasePath()}/workers/login';
  static Future<String> workerById(String workerId) async => '${await getBasePath()}/workers/$workerId';
  static Future<String> workerByPhone(String phone) async => '${await getBasePath()}/workers/phone/$phone';
  static Future<String> workerPolicy(String workerId) async => '${await getBasePath()}/workers/$workerId/policy';
  static Future<String> workerInsuranceSummary(String workerId) async => '${await getBasePath()}/workers/$workerId/insurance-summary';
  static Future<String> workerIncrementRides(String workerId) async => '${await getBasePath()}/workers/$workerId/rides/increment';
  static Future<String> workerDeductPremium(String workerId) async => '${await getBasePath()}/workers/$workerId/premium/deduct';
  static Future<String> workerWeeklyReset(String workerId) async => '${await getBasePath()}/workers/$workerId/weekly-reset';
  
  // Order Endpoints
  static Future<String> get orderReceive async => '${await getBasePath()}/orders/receive';
  static Future<String> orderWeather(String orderId) async => '${await getBasePath()}/orders/weather/$orderId';
  
  // Payout Endpoints
  static Future<String> get payoutTrigger async => '${await getBasePath()}/payout/trigger';
  static Future<String> payoutHistory(String workerId) async => '${await getBasePath()}/payout/history/$workerId';
  
  // Health Check
  static Future<String> get health async => '${await getBaseUrl()}/health';
  
  // Timeout configurations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  
  // HMAC Secret Key (should match backend SECRET_KEY)
  static const String hmacSecretKey = 'test-secret-key-for-testing-only';
  
  // Environment detection
  static Future<bool> get isProduction async {
    final baseUrl = await getBaseUrl();
    return baseUrl.contains('render.com') || baseUrl.contains('https://');
  }
  
  static Future<bool> get isDevelopment async => !(await isProduction);
}
