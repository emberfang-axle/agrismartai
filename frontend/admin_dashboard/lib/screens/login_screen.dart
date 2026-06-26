import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/agri_smart_logo.dart';

/// Modern admin login — centered card on slate background.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'admin@agrismartai.ph');
  final _password = TextEditingController(text: 'admin123');
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final notifier = ref.read(adminAuthProvider.notifier);
    final ok = await notifier.signIn(_email.text, _password.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notifier.lastError ?? 'Login failed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 960;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: wide ? _splitLayout() : _stackedLayout(),
    );
  }

  Widget _splitLayout() {
    return Row(
      children: [
        Expanded(child: _brandSide()),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: _loginCard(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stackedLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _brandSide(compact: true),
            const SizedBox(height: 24),
            _loginCard(),
          ],
        ),
      ),
    );
  }

  Widget _brandSide({bool compact = false}) {
    if (compact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        decoration: BoxDecoration(
          gradient: DashboardTheme.brandGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const AgriSmartLogo(size: 80, inverted: true),
            const SizedBox(height: 16),
            Text('Admin Command Center',
                style: TextStyle(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Rice Disease Monitoring • New Bataan',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(gradient: DashboardTheme.brandGradient),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AgriSmartLogo(size: 100, inverted: true, showGlow: true),
                  const SizedBox(height: 24),
                  Text(
                    'Admin Console for rice disease\nmonitoring in New Bataan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _feature(Icons.people_outline, 'Farmers'),
                      const SizedBox(width: 24),
                      _feature(Icons.analytics_outlined, 'Analytics'),
                      const SizedBox(width: 24),
                      _feature(Icons.verified_outlined, 'Reports'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feature(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 28),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
      ],
    );
  }

  Widget _loginCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(child: AgriSmartLogo(size: 56)),
            const SizedBox(height: 20),
            const Text('Admin sign in',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 6),
            const Text('Manage farmers, scans, and disease reports',
                style: TextStyle(color: AppColors.muted, fontSize: 14)),
            const SizedBox(height: 32),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Min 6 characters' : null,
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Sign in to dashboard'),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.softGreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.key_rounded, color: AppColors.primary, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Demo: admin@agrismartai.ph / admin123',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
