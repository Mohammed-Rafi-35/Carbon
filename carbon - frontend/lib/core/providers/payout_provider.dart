import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payout.dart';
import '../../data/models/sensor_data.dart';
import '../../data/repositories/payout_repository.dart';

/// Payout repository provider
final payoutRepositoryProvider = Provider<PayoutRepository>((ref) {
  return PayoutRepository();
});

/// Payout state
class PayoutState {
  final Payout? lastPayout;
  final List<Payout> history;
  final bool isLoading;
  final bool isLoadingHistory;
  final String? error;
  final String? successMessage;

  const PayoutState({
    this.lastPayout,
    this.history = const [],
    this.isLoading = false,
    this.isLoadingHistory = false,
    this.error,
    this.successMessage,
  });

  PayoutState copyWith({
    Payout? lastPayout,
    List<Payout>? history,
    bool? isLoading,
    bool? isLoadingHistory,
    String? error,
    String? successMessage,
  }) {
    return PayoutState(
      lastPayout: lastPayout ?? this.lastPayout,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      error: error,
      successMessage: successMessage,
    );
  }
}

/// Payout notifier
class PayoutNotifier extends StateNotifier<PayoutState> {
  final PayoutRepository _payoutRepository;

  PayoutNotifier(this._payoutRepository) : super(const PayoutState());

  /// Trigger payout with sensor data
  Future<Payout?> triggerPayout({
    required String workerId,
    required String orderId,
    required SensorData sensorData,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final payout = await _payoutRepository.triggerPayout(
        workerId: workerId,
        orderId: orderId,
        sensorData: sensorData,
      );

      state = state.copyWith(
        lastPayout: payout,
        isLoading: false,
        successMessage: payout.status == 'approved'
            ? 'Payout approved! ₹${payout.amount.toStringAsFixed(2)} credited to your wallet.'
            : 'Payout ${payout.status}. ${payout.reason}',
      );

      // Refresh history
      await loadPayoutHistory(workerId);

      return payout;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  /// Load payout history
  Future<void> loadPayoutHistory(String workerId) async {
    state = state.copyWith(isLoadingHistory: true, error: null);

    try {
      final history = await _payoutRepository.getPayoutHistory(workerId);

      state = state.copyWith(
        history: history,
        isLoadingHistory: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingHistory: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Clear messages
  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }

  /// Clear state
  void clearState() {
    state = const PayoutState();
  }
}

/// Payout provider
final payoutProvider = StateNotifierProvider<PayoutNotifier, PayoutState>((ref) {
  final payoutRepository = ref.watch(payoutRepositoryProvider);
  return PayoutNotifier(payoutRepository);
});

/// Convenience provider for payout history
final payoutHistoryProvider = Provider<List<Payout>>((ref) {
  return ref.watch(payoutProvider).history;
});
