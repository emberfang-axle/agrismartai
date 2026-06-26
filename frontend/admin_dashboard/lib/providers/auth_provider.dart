import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/admin_api_service.dart';
import 'data_mode_provider.dart';
import 'report_provider.dart';

final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, bool>((ref) => AdminAuthNotifier(ref));

final adminNameProvider = StateProvider<String>((ref) => 'Administrator');

final appBootProvider = FutureProvider<void>((ref) async {
  try {
    await AdminApiService.instance.init().timeout(const Duration(seconds: 4));
  } catch (_) {}
});

class AdminAuthNotifier extends StateNotifier<bool> {
  AdminAuthNotifier(this._ref) : super(false);

  final Ref _ref;

  static const _demoEmail = 'admin@agrismartai.ph';
  static const _demoPassword = 'admin123';

  String? lastError;

  Future<bool> restoreSession() async {
    final session = AdminApiService.instance.session;
    if (session == null) return false;
    _ref.read(adminNameProvider.notifier).state = session.fullName;
    _ref.read(dataModeProvider.notifier).state = DataMode.live;
    _ref.read(reportProvider.notifier).reload();
    state = true;
    return true;
  }

  Future<bool> signIn(String email, String password) async {
    lastError = null;
    final trimmed = email.trim().toLowerCase();

    if (AdminApiService.instance.isReady) {
      final ok = await AdminApiService.instance
          .signInAdmin(email.trim(), password)
          .timeout(const Duration(seconds: 8));
      if (ok) {
        final name = AdminApiService.instance.adminDisplayName();
        if (name != null && name.isNotEmpty) {
          _ref.read(adminNameProvider.notifier).state = name;
        }
        _ref.read(dataModeProvider.notifier).state = DataMode.live;
        _ref.read(reportProvider.notifier).reload();
        state = true;
        return true;
      }
    }

    if (trimmed == _demoEmail && password == _demoPassword) {
      _ref.read(dataModeProvider.notifier).state = DataMode.demo;
      _ref.read(adminNameProvider.notifier).state = 'Administrator';
      _ref.read(reportProvider.notifier).reload();
      state = true;
      return true;
    }

    lastError =
        'Invalid credentials. Demo: admin@agrismartai.ph / admin123';
    return false;
  }

  Future<void> signOut() async {
    await AdminApiService.instance.signOut();
    _ref.read(dataModeProvider.notifier).state = DataMode.demo;
    _ref.read(reportProvider.notifier).reload();
    state = false;
  }
}
