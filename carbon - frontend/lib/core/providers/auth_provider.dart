import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/auth_state.dart';
import '../../data/models/worker.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/storage/secure_storage.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState.initial()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await SecureStorage.isLoggedIn();
    if (!isLoggedIn) {
      state = AuthState.unauthenticated();
      return;
    }
    final workerId = await SecureStorage.getWorkerId();
    if (workerId == null) {
      state = AuthState.unauthenticated();
      return;
    }
    try {
      final worker = await _authRepository.getWorkerById(workerId);
      state = AuthState.authenticated(worker);
    } catch (_) {
      await SecureStorage.clearAll();
      state = AuthState.unauthenticated();
    }
  }

  Future<void> register({
    required String name,
    required String phone,
    required String password,
    required String zone,
    required String vehicleType,
    double? projectedWeeklyIncome,
  }) async {
    state = AuthState.loading();
    try {
      final worker = await _authRepository.register(
        name: name,
        phone: phone,
        password: password,
        zone: zone,
        vehicleType: vehicleType,
        projectedWeeklyIncome: projectedWeeklyIncome,
      );
      await _saveAndAuthenticate(worker);
    } catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> login({
    required String phone,
    required String password,
  }) async {
    state = AuthState.loading();
    try {
      final worker = await _authRepository.login(phone: phone, password: password);
      await _saveAndAuthenticate(worker);
    } catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _saveAndAuthenticate(Worker worker) async {
    await SecureStorage.saveWorkerCredentials(
      workerId: worker.id,
      name: worker.name,
      phone: worker.phone,
      zone: worker.zone,
      vehicleType: worker.vehicleType,
    );
    state = AuthState.authenticated(worker);
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
    state = AuthState.unauthenticated();
  }

  Future<void> refreshWorker() async {
    if (state.worker == null) return;
    try {
      final worker = await _authRepository.getWorkerById(state.worker!.id);
      state = AuthState.authenticated(worker);
    } catch (_) {
      // Keep current state if refresh fails silently
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

final currentWorkerProvider = Provider<Worker?>((ref) => ref.watch(authProvider).worker);
