import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../config/api_config.dart';

class HmacUtil {
  /// Generate HMAC-SHA256 signature for request authentication
  /// Matches backend security implementation
  static String generateSignature(String payload, String timestamp) {
    final message = '$payload:$timestamp';
    final key = utf8.encode(ApiConfig.hmacSecretKey);
    final bytes = utf8.encode(message);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  /// Get current Unix timestamp as string
  static String getCurrentTimestamp() {
    return (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
  }

  /// Create signed request headers
  static Map<String, String> createSignedHeaders(String payload) {
    final timestamp = getCurrentTimestamp();
    final signature = generateSignature(payload, timestamp);
    
    return {
      'X-Timestamp': timestamp,
      'X-Signature': signature,
      'Content-Type': 'application/json',
    };
  }
}
