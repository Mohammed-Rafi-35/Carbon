import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/auth_state.dart';
import '../../data/models/worker.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/storage/secure_storage.dart';

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState.initial()) {
    _checkAuthStatus();
  }

  /// Check if user is already logged in
  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await SecureStorage.isLoggedIn();
    
    if (isLoggedIn) {
      final workerId = await SecureStorage.getWorkerId();
      if (workerId != null) {
        try {
          final worker = await _authRepository.getWorkerById(workerId);
          state = AuthState.authenticated(worker);
        } catch (e) {
          // If fetching worker fails, clear storage and set unauthenticated
          await SecureStorage.clearAll();
          state = AuthState.unauthenticated();
        }
      } else {
        state = AuthState.unauthenticated();
      }
    } else {
      state = AuthState.unauthenticated();
    }
  }

  /// Register new worker
  Future<void> register({
    required String phone,
    required String zone,
    required String vehicleType,
  }) async {
    state = AuthState.loading();

    try {
      final worker = await _authRepository.register(
        phone: phone,
        zone: zone,
        vehicleType: vehicleType,
      );

      // Save credentials
      await SecureStorage.saveWorkerCredentials(
        workerId: worker.id,
        phone: worker.phone,
        zone: worker.zone,
        vehicleType: worker.vehicleType,
      );

      state = AuthState.authenticated(worker);
    } catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Login with phone
  Future<void> login(String phone) async {
    state = AuthState.loading();

    try {
      final worker = await _authRepository.login(phone);

      // Save credentials
      await SecureStorage.saveWorkerCredentials(
        workerId: worker.id,
        phone: worker.phone,
        zone: worker.zone,
        vehicleType: worker.vehicleType,
      );

      state = AuthState.authenticated(worker);
    } catch (e) {
      state = AuthState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Logout
  Future<void> logout() async {
    await SecureStorage.clearAll();
    state = AuthState.unauthenticated();
  }

  /// Refresh worker data
  Future<void> refreshWorker() async {
    if (state.worker == null) return;

    try {
      final worker = await _authRepository.getWorkerById(state.worker!.id);
      state = AuthState.authenticated(worker);
    } catch (e) {
      // Keep current state if refresh fails
    }
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});

/// Convenience provider for current worker
final currentWorkerProvider = Provider<Worker?>((ref) {
  return ref.watch(authProvider).worker;
});
