import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/scan_model.dart';
import '../models/scan_payload.dart';
import '../services/api_service.dart';
import '../services/chatbot_service.dart';
import '../services/postgresql_service.dart';
import '../services/validation_service.dart';
import '../utils/location.dart';
import 'auth_provider.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final validationServiceProvider =
    Provider<ValidationService>((ref) => ValidationService());
final chatbotServiceProvider = Provider<ChatbotService>(
  (ref) => ChatbotService(),
);

class ScanState {
  final bool loading;
  final List<ScanModel> history;
  final DetectionResult? lastResult;
  final String? lastImagePath;
  final Uint8List? lastImageBytes;
  final String? error;

  const ScanState({
    this.loading = false,
    this.history = const [],
    this.lastResult,
    this.lastImagePath,
    this.lastImageBytes,
    this.error,
  });

  String? get contextDisease => lastResult?.diseaseCode;

  ScanState copyWith({
    bool? loading,
    List<ScanModel>? history,
    DetectionResult? lastResult,
    String? lastImagePath,
    Uint8List? lastImageBytes,
    String? error,
    bool clearError = false,
  }) {
    return ScanState(
      loading: loading ?? this.loading,
      history: history ?? this.history,
      lastResult: lastResult ?? this.lastResult,
      lastImagePath: lastImagePath ?? this.lastImagePath,
      lastImageBytes: lastImageBytes ?? this.lastImageBytes,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final scanProvider =
    StateNotifierProvider<ScanNotifier, ScanState>((ref) => ScanNotifier(ref));

class ScanNotifier extends StateNotifier<ScanState> {
  final Ref _ref;
  ScanNotifier(this._ref) : super(const ScanState());

  PostgreSQLService get _db => _ref.read(postgresqlServiceProvider);
  ApiService get _api => _ref.read(apiServiceProvider);
  ValidationService get _validator => _ref.read(validationServiceProvider);

  Future<void> loadHistory() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final scans = await _db.fetchScans(user.id);
      state = state.copyWith(loading: false, history: scans);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<DetectionResult?> analyze(ScanPayload payload) async {
    final user = _ref.read(currentUserProvider);
    state = state.copyWith(
      loading: true,
      clearError: true,
      lastImagePath: payload.path,
      lastImageBytes: payload.bytes,
    );

    final prepared = _validator.prepareImageForScan(payload.bytes);
    // Defense mode: accept gallery uploads — backend handles simulated detection.
    final validation = _validator.validateBytes(
      prepared,
      fromCamera: true,
    );
    if (!validation.isRiceLeaf) {
      state = state.copyWith(loading: false, error: validation.reason);
      return null;
    }

    final coords = await getCurrentLocation();
    final isDemoUser = user != null && user.id.startsWith('demo-');

    final result = await _api.detect(
      imageBytes: prepared,
      isRiceLeaf: true,
      filename: payload.path?.split('/').last ?? 'leaf.jpg',
      userId: isDemoUser ? null : user?.id,
      barangay: user?.barangay ?? 'New Bataan',
      latitude: coords?.lat,
      longitude: coords?.lng,
    );

    // Save to PostgreSQL via backend for real (non-demo) users.
    if (user != null && !isDemoUser) {
      try {
        if (result.scanId != null && result.scanId!.isNotEmpty) {
          // Backend already saved it — just update local history.
          final saved = ScanModel(
            id: result.scanId!,
            userId: user.id,
            diseaseCode: result.diseaseCode,
            diseaseName: result.diseaseName,
            confidence: result.confidence,
            modelVersion: result.modelVersion,
            isRiceLeaf: result.isRiceLeaf,
            imagePath: payload.path,
            barangay: user.barangay,
            latitude: coords?.lat,
            longitude: coords?.lng,
            createdAt: DateTime.now(),
          );
          state = state.copyWith(history: [saved, ...state.history]);
        } else {
          // Backend couldn't save (no service key) — save from Flutter client.
          final saved = await _db.saveScan(
            user: user,
            result: result,
            imagePath: payload.path,
            imageBytes: prepared,
            latitude: coords?.lat,
            longitude: coords?.lng,
          );
          state = state.copyWith(history: [saved, ...state.history]);
        }
      } catch (_) {
        // Detection succeeded — show result even if cloud save failed.
      }
    } else if (user != null && isDemoUser) {
      // Demo user — save to in-memory list so history screen still shows it.
      final saved = await _db.saveScan(
        user: user,
        result: result,
        imagePath: payload.path,
        latitude: coords?.lat,
        longitude: coords?.lng,
      );
      state = state.copyWith(history: [saved, ...state.history]);
    }

    state = state.copyWith(loading: false, lastResult: result);
    return result;
  }

  void clear() {
    state = state.copyWith(
      lastResult: null,
      lastImagePath: null,
      lastImageBytes: null,
      clearError: true,
    );
  }

  Future<bool> deleteScan(String scanId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;
    try {
      await _db.deleteScan(user.id, scanId);
      state = state.copyWith(
        history: state.history.where((s) => s.id != scanId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> clearAllHistory() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return false;
    try {
      await _db.clearAllScans(user.id);
      state = state.copyWith(history: []);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final scanSummaryProvider = Provider<Map<String, int>>((ref) {
  final history = ref.watch(scanProvider).history;
  return {
    'total': history.length,
    'diseased': history.where((s) => !s.isHealthy).length,
    'healthy': history.where((s) => s.isHealthy).length,
  };
});

final backendOnlineProvider = FutureProvider<bool>((ref) async {
  return ref.read(apiServiceProvider).healthCheck();
});
