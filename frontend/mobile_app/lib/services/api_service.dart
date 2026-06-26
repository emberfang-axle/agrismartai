import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/scan_model.dart';
import '../utils/constants.dart';
import 'backend_availability.dart';
import 'local_detection_service.dart';

/// Python backend client for disease detection and chat.
class ApiService {
  final String baseUrl;
  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Future<DetectionResult> detect({
    required Uint8List imageBytes,
    required bool isRiceLeaf,
    String filename = 'leaf.jpg',
    String? userId,
    String barangay = 'New Bataan',
    double? latitude,
    double? longitude,
  }) async {
    if (!isRiceLeaf) {
      return const DetectionResult(
        diseaseCode: 'healthy',
        diseaseName: 'Not a Rice Leaf',
        confidence: 0,
        isRiceLeaf: false,
        message: 'Image rejected: not a valid rice leaf.',
      );
    }

    if (imageBytes.isEmpty) {
      return const DetectionResult(
        diseaseCode: 'healthy',
        diseaseName: 'Invalid Image',
        confidence: 0,
        isRiceLeaf: false,
        message: 'No image data received. Please retake the photo.',
      );
    }

    if (BackendAvailability.forceOffline ||
        BackendAvailability.isKnownOffline ||
        !await BackendAvailability.isOnline()) {
      return LocalDetectionService.simulate(imageBytes);
    }

    try {
      final uri = Uri.parse('$baseUrl/api/detect');
      final request = http.MultipartRequest('POST', uri)
        ..fields['barangay'] = barangay;

      if (userId != null && userId.isNotEmpty) {
        request.fields['user_id'] = userId;
      }
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();

      final safeName = filename.toLowerCase().endsWith('.jpg') ||
              filename.toLowerCase().endsWith('.jpeg')
          ? filename
          : 'leaf.jpg';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: safeName,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return DetectionResult.fromMap(body);
      }
      throw Exception(
        'Detection failed (HTTP ${response.statusCode}).',
      );
    } catch (_) {
      BackendAvailability.markOffline();
      return LocalDetectionService.simulate(imageBytes);
    }
  }

  Future<String?> chat({
    required String message,
    String? contextDisease,
    List<Map<String, String>> history = const [],
    String? userId,
  }) async {
    if (BackendAvailability.forceOffline || BackendAvailability.isKnownOffline) {
      return null;
    }
    try {
      final uri = Uri.parse('$baseUrl/api/chat');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message,
              'context_disease': contextDisease,
              'history': history,
              if (userId != null) 'user_id': userId,
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['reply']?.toString();
      }
    } catch (_) {}
    return null;
  }

  Future<bool> healthCheck() async {
    if (BackendAvailability.forceOffline) return false;
    return BackendAvailability.isOnline();
  }
}
