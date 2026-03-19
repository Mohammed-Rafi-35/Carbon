import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/order.dart';
import '../../data/repositories/order_repository.dart';

/// Order repository provider
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

/// Order state
class OrderState {
  final Order? currentOrder;
  final bool isLoading;
  final bool isLoadingWeather;
  final String? error;

  const OrderState({
    this.currentOrder,
    this.isLoading = false,
    this.isLoadingWeather = false,
    this.error,
  });

  OrderState copyWith({
    Order? currentOrder,
    bool? isLoading,
    bool? isLoadingWeather,
    String? error,
  }) {
    return OrderState(
      currentOrder: currentOrder ?? this.currentOrder,
      isLoading: isLoading ?? this.isLoading,
      isLoadingWeather: isLoadingWeather ?? this.isLoadingWeather,
      error: error,
    );
  }
}

/// Order notifier
class OrderNotifier extends StateNotifier<OrderState> {
  final OrderRepository _orderRepository;

  OrderNotifier(this._orderRepository) : super(const OrderState());

  /// Receive new order
  Future<Order?> receiveOrder({
    required String workerId,
    required double pickupLat,
    required double pickupLon,
    double? dropoffLat,
    double? dropoffLon,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final order = await _orderRepository.receiveOrder(
        workerId: workerId,
        pickupLat: pickupLat,
        pickupLon: pickupLon,
        dropoffLat: dropoffLat,
        dropoffLon: dropoffLon,
      );

      state = state.copyWith(
        currentOrder: order,
        isLoading: false,
      );

      return order;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  /// Load weather data for current order (lazy loading)
  Future<void> loadWeatherData() async {
    if (state.currentOrder == null) return;

    state = state.copyWith(isLoadingWeather: true, error: null);

    try {
      final updatedOrder = await _orderRepository.updateOrderWithWeather(
        state.currentOrder!,
      );

      state = state.copyWith(
        currentOrder: updatedOrder,
        isLoadingWeather: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingWeather: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Clear current order
  void clearOrder() {
    state = const OrderState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Order provider
final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  return OrderNotifier(orderRepository);
});

/// Convenience provider for current order
final currentOrderProvider = Provider<Order?>((ref) {
  return ref.watch(orderProvider).currentOrder;
});
