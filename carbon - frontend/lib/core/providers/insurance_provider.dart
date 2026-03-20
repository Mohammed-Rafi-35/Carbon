import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/insurance_summary.dart';
import '../../data/repositories/insurance_repository.dart';

final insuranceRepositoryProvider = Provider<InsuranceRepository>(
  (ref) => InsuranceRepository(),
);

class InsuranceState {
  final InsuranceSummary? summary;
  final bool isLoading;
  final String? error;

  const InsuranceState({this.summary, this.isLoading = false, this.error});

  InsuranceState copyWith({
    InsuranceSummary? summary,
    bool? isLoading,
    String? error,
  }) {
    return InsuranceState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class InsuranceNotifier extends StateNotifier<InsuranceState> {
  final InsuranceRepository _repo;

  InsuranceNotifier(this._repo) : super(const InsuranceState());

  Future<void> loadSummary(String workerId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final summary = await _repo.getInsuranceSummary(workerId);
      state = state.copyWith(summary: summary, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> incrementRides(String workerId) async {
    try {
      await _repo.incrementRides(workerId);
      await loadSummary(workerId); // Refresh to show new tier
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> deductPremium(String workerId) async {
    try {
      await _repo.deductPremium(workerId);
      await loadSummary(workerId);
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

final insuranceProvider =
    StateNotifierProvider<InsuranceNotifier, InsuranceState>((ref) {
  return InsuranceNotifier(ref.watch(insuranceRepositoryProvider));
});
