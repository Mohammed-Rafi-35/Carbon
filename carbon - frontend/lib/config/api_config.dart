/// API Configuration
/// Centralized endpoint management for easy deployment changes
class ApiConfig {
  // Base URL - Change this when deploying to production
  static const String baseUrl = 'http://127.0.0.1:8000';
  
  // API Version
  static const String apiVersion = '/api/v1';
  
  // Full base path
  static String get basePath => '$baseUrl$apiVersion';
  
  // Worker Endpoints
  static String get workerRegister => '$basePath/workers/register';
  static String workerById(String workerId) => '$basePath/workers/$workerId';
  static String workerByPhone(String phone) => '$basePath/workers/phone/$phone';
  
  // Order Endpoints
  static String get orderReceive => '$basePath/orders/receive';
  static String orderWeather(String orderId) => '$basePath/orders/weather/$orderId';
  
  // Payout Endpoints
  static String get payoutTrigger => '$basePath/payout/trigger';
  static String payoutHistory(String workerId) => '$basePath/payout/history/$workerId';
  
  // Health Check
  static String get health => '$baseUrl/health';
  
  // Timeout configurations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  
  // HMAC Secret Key (should match backend SECRET_KEY)
  static const String hmacSecretKey = 'test-secret-key-for-testing-only';
}
