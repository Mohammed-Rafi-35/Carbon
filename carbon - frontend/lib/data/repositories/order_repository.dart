import 'package:dio/dio.dart';
import '../../config/api_config.dart';
import '../../core/network/api_client.dart';
import '../models/order.dart';
import '../models/weather.dart';

/// Order repository — Phase 1 & 2 implementation
class OrderRepository {
  final ApiClient _apiClient;

  OrderRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Receive new order with GPS coordinates.
  ///
  /// Generates a unique order_id client-side (UUID v4 format) and sends it
  /// with pickup/dropoff coordinates. Backend synthesizes weather and returns
  /// an OrderResponse with embedded weather data.
  Future<Order> receiveOrder({
    required String workerId,
    required double pickupLat,
    required double pickupLon,
    double? dropoffLat,
    double? dropoffLon,
  }) async {
    try {
      // Generate unique order ID — backend requires this field
      final orderId = _generateOrderId();

      final endpoint = await ApiConfig.orderReceive;
      final response = await _apiClient.post(
        endpoint,
        data: {
          'worker_id': workerId,
          'order_id': orderId,
          'pickup_lat': pickupLat,
          'pickup_lon': pickupLon,
          // Backend requires dropoff coords (ge/le validators) — use pickup as fallback
          'dropoff_lat': dropoffLat ?? pickupLat,
          'dropoff_lon': dropoffLon ?? pickupLon,
        },
      );

      return Order.fromJson(response.data as Map<String, dynamic>);
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
      final endpoint = await ApiConfig.orderWeather(orderId);
      final response = await _apiClient.get(endpoint);
      return Weather.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Order not found');
      }
      throw Exception('Failed to fetch weather: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch weather: $e');
    }
  }

  /// Update order with freshly fetched weather data
  Future<Order> updateOrderWithWeather(Order order) async {
    final weather = await getOrderWeather(order.id);
    return order.copyWith(weather: weather);
  }

  /// Generate a unique order ID using timestamp + random suffix
  String _generateOrderId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = (ts % 99999).toString().padLeft(5, '0');
    return 'ORD-$ts-$rand';
  }
}
