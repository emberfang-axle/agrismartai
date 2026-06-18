import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config.dart';

/// Routes chat through FastAPI `/chat` when available; falls back to DeepSeek direct.
class ChatRepository {
  static const _localPrompt = '''
You are AgriSmartAI — warm rice farming assistant for Batinao, New Bataan farmers.
Reply in the farmer's language (English, Tagalog, or Taglish).
Explain scan results clearly. Give practical steps. Recommend DA for severe cases.
''';

  Future<String> send({
    required List<Map<String, String>> messages,
    Map<String, dynamic>? scanContext,
  }) async {
    // Try backend chat API first
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.apiBaseUrl}/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'messages': messages, 'scan_context': scanContext}),
          )
          .timeout(const Duration(seconds: 35));
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as Map)['reply'] as String;
      }
    } catch (_) {}

    // Direct DeepSeek fallback
    if (AppConfig.deepSeekApiKey != 'YOUR_DEEPSEEK_API_KEY') {
      try {
        final apiMessages = <Map<String, String>>[
          {'role': 'system', 'content': _localPrompt},
          if (scanContext != null)
            {'role': 'system', 'content': 'Scan context: ${jsonEncode(scanContext)}'},
          ...messages,
        ];
        final response = await http
            .post(
              Uri.parse(AppConfig.deepSeekApiUrl),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${AppConfig.deepSeekApiKey}',
              },
              body: jsonEncode({
                'model': AppConfig.deepSeekModel,
                'messages': apiMessages,
                'temperature': 0.7,
                'max_tokens': 600,
              }),
            )
            .timeout(const Duration(seconds: 35));
        if (response.statusCode == 200) {
          return (jsonDecode(response.body) as Map)['choices'][0]['message']['content'] as String;
        }
      } catch (_) {}
    }

    return _taglishFallback(messages.last['content'] ?? '', scanContext);
  }

  String _taglishFallback(String question, Map<String, dynamic>? ctx) {
    final q = question.toLowerCase();
    final disease = ctx?['disease']?.toString() ?? '';
    if (q.contains('treat') || q.contains('gamot') || q.contains('gawin')) {
      return '**Treatment steps:**\n• Ayusin ang drainage\n• Sundin ang fertilizer sa scan result\n• DA-approved spray kung kailangan\n• Pumunta sa DA office para sa libreng konsulta';
    }
    if (q.contains('cause') || q.contains('sanhi') || q.contains('ano')) {
      return disease.isNotEmpty
          ? 'Ang **$disease** ay common sa basang paddies. Kumakalat sa tubig at hangin. Tanggalin agad ang infected plants.'
          : 'Ang rice diseases ay kumakalat sa tubig, leafhoppers, at infected seeds.';
    }
    if (disease.isNotEmpty) {
      return 'Nakita natin ang **$disease** sa scan mo. Tanungin: "Paano i-treat?" o "Dapat ba pumunta sa DA?"';
    }
    return 'Kumusta! Ako si AgriSmartAI. Magtanong ka sa Taglish o English about rice diseases, treatment, o DA office.';
  }
}
