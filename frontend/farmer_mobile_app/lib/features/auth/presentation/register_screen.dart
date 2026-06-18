import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../../core/di/providers.dart';
import '../../../shared/branding/app_brand.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_card.dart';
import '../../home/presentation/main_shell.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _barangay = AppConstants.barangays.first;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authRepositoryProvider).signUp(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
            fullName: _nameCtrl.text.trim(),
            barangay: _barangay,
          );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(slideFadeRoute(const MainShell()), (_) => false);
      }
    } catch (_) {
      setState(() => _error = 'Registration failed. Email may already exist.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account'), backgroundColor: AppBrand.background),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Join AgriSmartAI', style: AppBrand.heading2),
              const SizedBox(height: 4),
              Text('Register — Batinao, New Bataan', style: AppBrand.body),
              const SizedBox(height: 24),
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 16),
              TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
              const SizedBox(height: 16),
              TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline))),
              const SizedBox(height: 16),
              TextField(controller: _confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline))),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _barangay,
                decoration: const InputDecoration(labelText: 'Barangay', prefixIcon: Icon(Icons.location_on_outlined)),
                items: AppConstants.barangays.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                onChanged: (v) => setState(() => _barangay = v!),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: AppBrand.body.copyWith(color: Colors.red.shade700)),
              ],
              const SizedBox(height: 24),
              GoldButton(label: 'Register', loading: _loading, onPressed: _register),
            ],
          ),
        ),
      ),
    );
  }
}
