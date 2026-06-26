import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/admin_supabase_service.dart';
import '../utils/app_config.dart';
import 'data_mode_provider.dart';
import 'report_provider.dart';

/// True when an admin is logged in.
final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, bool>((ref) => AdminAuthNotifier(ref));

final adminNameProvider = StateProvider<String>((ref) => 'Administrator');

/// Initializes Supabase in the background — never blocks the login screen.
final appBootProvider = FutureProvider<void>((ref) async {
  if (!AppConfig.isSupabaseConfigured) return;
  try {
    await AdminSupabaseService.init().timeout(const Duration(seconds: 4));
    await ref
        .read(adminAuthProvider.notifier)
        .restoreSession()
        .timeout(const Duration(seconds: 4));
  } catch (_) {}
});

class AdminAuthNotifier extends StateNotifier<bool> {
  AdminAuthNotifier(this._ref) : super(false);

  final Ref _ref;

  static const _demoEmail = 'admin@agrismartai.ph';
  static const _demoPassword = 'admin123';

  String? lastError;

  Future<bool> restoreSession() async {
    if (!AdminSupabaseService.instance.isReady) return false;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;
      final ok = await AdminSupabaseService.instance
          .isStaffUser()
          .timeout(const Duration(seconds: 4));
      if (!ok) {
        await AdminSupabaseService.instance.signOut();
        return false;
      }
      final name = await AdminSupabaseService.instance
          .adminDisplayName()
          .timeout(const Duration(seconds: 4));
      if (name != null && name.isNotEmpty) {
        _ref.read(adminNameProvider.notifier).state = name;
      }
      _ref.read(dataModeProvider.notifier).state = DataMode.live;
      _ref.read(reportProvider.notifier).reload();
      state = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    lastError = null;
    final trimmed = email.trim().toLowerCase();

    // Try real Supabase login first (works for any credentials including default admin).
    if (AdminSupabaseService.instance.isReady) {
      try {
        final ok = await AdminSupabaseService.instance
            .signInAdmin(email.trim(), password)
            .timeout(const Duration(seconds: 8));
        if (ok) {
          final name = await AdminSupabaseService.instance
              .adminDisplayName()
              .timeout(const Duration(seconds: 4));
          if (name != null && name.isNotEmpty) {
            _ref.read(adminNameProvider.notifier).state = name;
          }
          _ref.read(dataModeProvider.notifier).state = DataMode.live;
          _ref.read(reportProvider.notifier).reload();
          state = true;
          return true;
        }
      } catch (_) {}
    }

    // Offline demo fallback — only for the known demo credentials.
    if (trimmed == _demoEmail && password == _demoPassword) {
      _ref.read(dataModeProvider.notifier).state = DataMode.demo;
      _ref.read(adminNameProvider.notifier).state = 'Administrator';
      _ref.read(reportProvider.notifier).reload();
      state = true;
      return true;
    }

    lastError = 'Invalid credentials. Try admin@agrismartai.ph / admin123';
    return false;
  }

  Future<void> signOut() async {
    await AdminSupabaseService.instance.signOut();
    _ref.read(dataModeProvider.notifier).state = DataMode.demo;
    _ref.read(reportProvider.notifier).reload();
    state = false;
  }
}
