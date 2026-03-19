import 'dart:convert';
import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/hmac_util.dart';
import '../models/payout.dart';
import '../models/sensor_data.dart';

/// Payout repository for secure payout operations
class PayoutRepository {
  final ApiClient _apiClient;

  PayoutRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Trigger payout with HMAC signature
  Future<Payout> triggerPayout({
    required String workerId,
    required String orderId,
    required SensorData sensorData,
  }) async {
    try {
      // Prepare payload
      final payload = {
        'worker_id': workerId,
        'order_id': orderId,
        'gps_speed_kmh': sensorData.gpsSpeedKmh,
        'accelerometer_variance': sensorData.accelerometerVariance,
        'latitude': sensorData.latitude,
        'longitude': sensorData.longitude,
      };

      // Generate timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Generate HMAC signature
      final payloadString = jsonEncode(payload);
      final signature = HmacUtil.generateSignature(payloadString, timestamp);

      // Make request with HMAC headers
      final response = await _apiClient.post(
        ApiConfig.payoutTrigger,
        data: payload,
        options: Options(
          headers: {
            'X-Signature': signature,
            'X-Timestamp': timestamp,
          },
        ),
      );

      return Payout.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('detail')) {
          throw Exception(errorData['detail']);
        }
        throw Exception('Invalid payout request');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Invalid HMAC signature. Security check failed.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Worker or order not found');
      }
      throw Exception('Failed to trigger payout: ${e.message}');
    } catch (e) {
      throw Exception('Failed to trigger payout: $e');
    }
  }

  /// Get payout history for worker
  Future<List<Payout>> getPayoutHistory(String workerId) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.payoutHistory(workerId),
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((json) => Payout.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Worker not found');
      }
      throw Exception('Failed to fetch payout history: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch payout history: $e');
    }
  }
}
