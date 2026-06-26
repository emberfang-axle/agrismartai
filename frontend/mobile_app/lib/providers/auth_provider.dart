import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/postgresql_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final postgresqlServiceProvider = Provider<PostgreSQLService>(
  (ref) => PostgreSQLService.instance,
);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(postgresqlServiceProvider)),
);

final currentUserProvider = Provider<UserModel?>(
  (ref) => ref.watch(authProvider).user,
);

class AuthNotifier extends StateNotifier<AuthState> {
  final PostgreSQLService _service;
  AuthNotifier(this._service) : super(const AuthState());

  Future<void> bootstrap() async {
    try {
      await _service.init();
      final user = await _service.currentUser().timeout(const Duration(seconds: 3));
      state = state.copyWith(
        status: user != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        user: user,
      );
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _service
          .signIn(email: email, password: password)
          .timeout(const Duration(seconds: 8));
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _readable(e),
      );
      return false;
    }
  }

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
    String barangay = 'New Bataan',
    String? phone,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _service.signUp(
        fullName: fullName,
        email: email,
        password: password,
        barangay: barangay,
        phone: phone,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _readable(e),
      );
      return false;
    }
  }

  Future<void> updateProfile(UserModel user) async {
    await _service.updateProfile(user);
    state = state.copyWith(user: user);
  }

  Future<void> resetPassword(String email) async {
    await _service.resetPassword(email);
  }

  Future<void> signOut() async {
    await _service.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> deleteAccount() async {
    final user = state.user;
    if (user == null) return;
    await _service.deleteAccount(user.id);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  String _readable(Object e) {
    final msg = e.toString().replaceFirst('Exception: ', '');
    return msg.isEmpty ? 'Something went wrong. Please try again.' : msg;
  }
}
