import 'package:equatable/equatable.dart';
import '../models/worker.dart';

/// Authentication state
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Auth state class
class AuthState extends Equatable {
  final AuthStatus status;
  final Worker? worker;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.worker,
    this.errorMessage,
  });

  /// Initial state
  factory AuthState.initial() => const AuthState(
        status: AuthStatus.initial,
      );

  /// Loading state
  factory AuthState.loading() => const AuthState(
        status: AuthStatus.loading,
      );

  /// Authenticated state
  factory AuthState.authenticated(Worker worker) => AuthState(
        status: AuthStatus.authenticated,
        worker: worker,
      );

  /// Unauthenticated state
  factory AuthState.unauthenticated() => const AuthState(
        status: AuthStatus.unauthenticated,
      );

  /// Error state
  factory AuthState.error(String message) => AuthState(
        status: AuthStatus.error,
        errorMessage: message,
      );

  /// Copy with
  AuthState copyWith({
    AuthStatus? status,
    Worker? worker,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      worker: worker ?? this.worker,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, worker, errorMessage];
}
