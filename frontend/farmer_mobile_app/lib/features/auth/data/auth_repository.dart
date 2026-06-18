import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/user_profile.dart';

class AuthRepository {
  final SupabaseClient _client;
  AuthRepository(this._client);

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<UserProfile?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _client.from('profiles').select().eq('id', user.id).maybeSingle();
    if (data == null) {
      return UserProfile(
        id: user.id,
        fullName: user.userMetadata?['full_name']?.toString() ?? 'Farmer',
        email: user.email ?? '',
        barangay: user.userMetadata?['barangay']?.toString() ?? 'Batinao',
        createdAt: DateTime.now(),
      );
    }
    return UserProfile.fromJson({...data, 'email': user.email});
  }

  Future<void> signIn(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String barangay,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'barangay': barangay},
    );
    final user = response.user;
    if (user != null) {
      await _client.from('profiles').upsert({
        'id': user.id,
        'full_name': fullName,
        'email': email,
        'barangay': barangay,
      });
    }
  }

  Future<void> resetPassword(String email) =>
      _client.auth.resetPasswordForEmail(email);

  Future<void> signOut() => _client.auth.signOut();

  Future<void> updateProfile({required String fullName, required String barangay}) async {
    final user = currentUser;
    if (user == null) return;
    await _client.from('profiles').upsert({
      'id': user.id,
      'full_name': fullName,
      'email': user.email,
      'barangay': barangay,
    });
  }
}
