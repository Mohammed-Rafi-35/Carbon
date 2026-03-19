import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../../core/network/api_client.dart';
import '../models/order.dart';
import '../models/weather.dart';

/// Order repository for order and weather operations
class OrderRepository {
  final ApiClient _apiClient;

  OrderRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Receive new order with GPS coordinates
  Future<Order> receiveOrder({
    required String workerId,
    required double pickupLat,
    required double pickupLon,
    double? dropoffLat,
    double? dropoffLon,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.orderReceive,
        data: {
          'worker_id': workerId,
          'pickup_lat': pickupLat,
          'pickup_lon': pickupLon,
          if (dropoffLat != null) 'dropoff_lat': dropoffLat,
          if (dropoffLon != null) 'dropoff_lon': dropoffLon,
        },
      );

      return Order.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Worker not found');
      }
      throw Exception('Failed to receive order: ${e.message}');
    } catch (e) {
      throw Exception('Failed to receive order: $e');
    }
  }

  /// Get weather data for specific order (lazy loading)
  Future<Weather> getOrderWeather(String orderId) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.orderWeather(orderId),
      );

      return Weather.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Order not found');
      }
      throw Exception('Failed to fetch weather: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch weather: $e');
    }
  }

  /// Update order with weather data
  Future<Order> updateOrderWithWeather(Order order) async {
    try {
      final weather = await getOrderWeather(order.id);
      return order.copyWith(weather: weather);
    } catch (e) {
      throw Exception('Failed to update order with weather: $e');
    }
  }
}
