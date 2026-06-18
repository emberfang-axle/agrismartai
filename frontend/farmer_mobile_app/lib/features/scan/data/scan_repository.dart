import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/scan_result.dart';

class ScanRepository {
  final SupabaseClient _client;
  ScanRepository(this._client);

  Future<List<ScanResult>> fetchScans(String userId) async {
    final rows = await _client.from('scans').select().eq('user_id', userId).order('created_at', ascending: false);
    return (rows as List).map((e) => ScanResult.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<ScanResult> saveScan({
    required String userId,
    required ScanResult result,
    File? imageFile,
  }) async {
    String? imageUrl = result.imageUrl;
    if (imageFile != null) {
      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _client.storage.from('scan-images').upload(path, imageFile);
      imageUrl = _client.storage.from('scan-images').getPublicUrl(path);
    }
    final row = await _client
        .from('scans')
        .insert({...result.toInsertJson(userId), 'image_url': imageUrl})
        .select()
        .single();
    return ScanResult.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> clearHistory(String userId) =>
      _client.from('scans').delete().eq('user_id', userId);

  Future<Map<String, dynamic>> getStats(String userId) async {
    final scans = await fetchScans(userId);
    if (scans.isEmpty) return {'totalScans': 0, 'accuracyRate': 0.0, 'streak': 0};
    final avg = scans.map((s) => s.confidence).reduce((a, b) => a + b) / scans.length;
    return {'totalScans': scans.length, 'accuracyRate': avg * 100, 'streak': _streak(scans)};
  }

  int _streak(List<ScanResult> scans) {
    int streak = 0;
    DateTime? last;
    for (final s in scans) {
      final d = s.createdAt;
      if (d == null) continue;
      final day = DateTime(d.year, d.month, d.day);
      if (last == null) {
        streak = 1;
        last = day;
      } else if (last.difference(day).inDays == 1) {
        streak++;
        last = day;
      } else if (last.difference(day).inDays > 1) break;
    }
    return streak;
  }
}
