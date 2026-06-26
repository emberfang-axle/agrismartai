import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/agri_brand_logo.dart';
import '../widgets/gold_button.dart';
import 'main_shell.dart';
import 'register_screen.dart';

const _kRememberEmail = 'remembered_email';

/// Professional split-layout login (web) / stacked (mobile).
class LoginScreen extends ConsumerStatefulWidget {
  static const route = '/login';
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _remember = false;

  @override
  void initState() {
    super.initState();
    _loadRemembered();
  }

  Future<void> _loadRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kRememberEmail);
    if (saved != null && mounted) {
      setState(() {
        _email.text = saved;
        _remember = true;
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final prefs = await SharedPreferences.getInstance();
    if (_remember) {
      await prefs.setString(_kRememberEmail, _email.text.trim());
    } else {
      await prefs.remove(_kRememberEmail);
    }
    final ok = await ref
        .read(authProvider.notifier)
        .signIn(_email.text.trim(), _password.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, MainShell.route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(authProvider).error ?? 'Login failed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).status == AuthStatus.loading;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: wide ? _wideLayout(context, loading) : _narrowLayout(context, loading),
    );
  }

  Widget _loginCard(BuildContext context, bool loading) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(32),
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
            Text('Sign in',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    )),
            const SizedBox(height: 6),
            const Text('Access your rice disease dashboard',
                style: TextStyle(color: AppColors.muted, fontSize: 14)),
            const SizedBox(height: 28),
            if (!AppConfig.isSupabaseConfigured) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.aiBlueLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.aiBlue.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.aiBlue, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Demo: any email + password (6+ chars) — PostgreSQL when backend is running',
                        style: TextStyle(fontSize: 12, color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email address',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
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
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _remember,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _remember = v ?? false),
                ),
                const Text('Remember email', style: TextStyle(fontSize: 13)),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text('Forgot?', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GoldButton(
              label: 'Sign In',
              loading: loading,
              icon: Icons.login_rounded,
              onPressed: _submit,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('New farmer?', style: TextStyle(color: AppColors.muted)),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, RegisterScreen.route),
                  child: const Text('Create account',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _wideLayout(BuildContext context, bool loading) {
    return Row(
      children: [
        const Expanded(child: _LoginBrandPanel()),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: _loginCard(context, loading),
            ),
          ),
        ),
      ],
    );
  }

  Widget _narrowLayout(BuildContext context, bool loading) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF072A15), Color(0xFF0B3B1F), Color(0xFF1B5E3A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  const AgriSmartLogo(size: 72, showGlow: true),
                  const SizedBox(height: 16),
                  const Text('AgriSmartAI',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(AppConfig.location,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _loginCard(context, loading),
          ],
        ),
      ),
    );
  }
}

class _LoginBrandPanel extends StatelessWidget {
  const _LoginBrandPanel();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1F0D), Color(0xFF1B5E20), Color(0xFF2E7D32)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AgriSmartLogo(size: 96, showGlow: true),
                  const SizedBox(height: 28),
                  const Text(
                    'AgriSmartAI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppConfig.tagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: const [
                      _Pill('AI Detection'),
                      _Pill('New Bataan'),
                      _Pill('Rice Monitoring'),
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
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}
