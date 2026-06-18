import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/chat/data/chat_repository.dart';
import '../../features/scan/data/detection_repository.dart';
import '../../features/scan/data/scan_repository.dart';
import '../../features/scan/domain/scan_result.dart';
import '../../features/auth/domain/user_profile.dart';

final supabaseProvider = Provider<SupabaseClient>((_) => Supabase.instance.client);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseProvider)),
);

final scanRepositoryProvider = Provider<ScanRepository>(
  (ref) => ScanRepository(ref.watch(supabaseProvider)),
);

final detectionRepositoryProvider = Provider<DetectionRepository>(
  (ref) => const DetectionRepository(),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(),
);

final authStateProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges,
);

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).getProfile();
});

final scansProvider = FutureProvider<List<ScanResult>>((ref) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return [];
  return ref.watch(scanRepositoryProvider).fetchScans(user.id);
});

final userStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return {'totalScans': 0, 'accuracyRate': 0.0, 'streak': 0};
  return ref.watch(scanRepositoryProvider).getStats(user.id);
});

final scanContextProvider = StateProvider<ScanResult?>((ref) => null);

final darkModeProvider = StateProvider<bool>((ref) => false);
