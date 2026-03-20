import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/admin_repository.dart';

class AdminState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? dashboard;
  final Map<String, dynamic>? fraudQueue;
  final Map<String, dynamic>? analytics;
  final Map<String, dynamic>? workerList;
  final String adminKey;

  const AdminState({
    this.isLoading = false,
    this.error,
    this.dashboard,
    this.fraudQueue,
    this.analytics,
    this.workerList,
    this.adminKey = '',
  });

  AdminState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? dashboard,
    Map<String, dynamic>? fraudQueue,
    Map<String, dynamic>? analytics,
    Map<String, dynamic>? workerList,
    String? adminKey,
  }) =>
      AdminState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        dashboard: dashboard ?? this.dashboard,
        fraudQueue: fraudQueue ?? this.fraudQueue,
        analytics: analytics ?? this.analytics,
        workerList: workerList ?? this.workerList,
        adminKey: adminKey ?? this.adminKey,
      );
}

class AdminNotifier extends StateNotifier<AdminState> {
  final AdminRepository _repo;

  AdminNotifier(this._repo) : super(const AdminState());

  Future<bool> authenticate(String key) async {
    state = state.copyWith(isLoading: true);
    try {
      final dashboard = await _repo.getDashboard(key);
      state = state.copyWith(
        isLoading: false,
        adminKey: key,
        dashboard: dashboard,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> loadDashboard() async {
    if (state.adminKey.isEmpty) return;
    state = state.copyWith(isLoading: true);
    try {
      final dashboard = await _repo.getDashboard(state.adminKey);
      state = state.copyWith(isLoading: false, dashboard: dashboard);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadFraudQueue() async {
    if (state.adminKey.isEmpty) return;
    state = state.copyWith(isLoading: true);
    try {
      final queue = await _repo.getFraudQueue(state.adminKey);
      state = state.copyWith(isLoading: false, fraudQueue: queue);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadAnalytics({int days = 7}) async {
    if (state.adminKey.isEmpty) return;
    state = state.copyWith(isLoading: true);
    try {
      final analytics =
          await _repo.getDisruptionAnalytics(state.adminKey, days: days);
      state = state.copyWith(isLoading: false, analytics: analytics);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadWorkers() async {
    if (state.adminKey.isEmpty) return;
    state = state.copyWith(isLoading: true);
    try {
      final workers = await _repo.listWorkers(state.adminKey);
      state = state.copyWith(isLoading: false, workerList: workers);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> deactivateWorker(String workerId) async {
    try {
      await _repo.deactivateWorker(state.adminKey, workerId);
      await loadWorkers();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> reactivateWorker(String workerId) async {
    try {
      await _repo.reactivateWorker(state.adminKey, workerId);
      await loadWorkers();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>?> getWorkerDataReport(String workerId) async {
    try {
      return await _repo.getWorkerDataReport(state.adminKey, workerId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  void logout() => state = const AdminState();
}

final adminRepositoryProvider =
    Provider<AdminRepository>((ref) => AdminRepository());

final adminProvider =
    StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier(ref.watch(adminRepositoryProvider));
});
