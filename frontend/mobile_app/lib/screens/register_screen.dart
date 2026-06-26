import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/app_decoration.dart';
import 'main_shell.dart';

/// Farmer registration — matches modern login design.
class RegisterScreen extends ConsumerStatefulWidget {
  static const route = '/register';
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String _barangay = 'Cabinuangan';

  static const _barangays = [
    'Cabinuangan', 'Andap', 'Magsaysay', 'Batinao', 'Bulahan',
    'Camanlangan', 'Kahayag', 'Katipunan', 'Manurigao', 'Pagsabangan',
  ];

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).signUp(
          fullName: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          barangay: _barangay,
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        );
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(
          context, MainShell.route, (r) => false);
    } else {
      final err = ref.read(authProvider).error ?? 'Registration failed';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    }
  }

  InputDecoration _field(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      );

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).status == AuthStatus.loading;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.deepGreen,
        elevation: 0,
      ),
      body: AgricultureBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppDecoration.card(),
                    child: Row(
                      children: [
                        const AgriLogo(size: 48),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Join AgriSmartAI',
                                  style: Theme.of(context).textTheme.titleLarge),
                              Text('Register as a New Bataan rice farmer',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.muted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.05, end: 0),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _name,
                    decoration: _field('Full Name', Icons.person_outline),
                    validator: (v) =>
                        (v == null || v.trim().length < 2) ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _field('Email', Icons.email_outlined),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: _field('Phone (optional)', Icons.phone_outlined),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _barangay,
                    decoration: _field('Barangay', Icons.location_on_outlined),
                    items: _barangays
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) => setState(() => _barangay = v ?? _barangay),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: _field('Password', Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Min 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.4),
                            )
                          : const Text('Create Account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
