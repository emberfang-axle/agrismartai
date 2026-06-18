// OBJECTIVE 3: AI chatbot — fertilizer guidance, DA referral, scan context Q&A
// REPLACE WITH REAL API KEY FOR PRODUCTION (DeepSeek / Gemini / Groq / OpenAI)

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum AiProvider { deepseek, openai, gemini, groq }

class AiService {
  static const _apiKeyPref = 'ai_api_key';
  static const _providerPref = 'ai_provider';

  static Future<bool> hasApiKey() async {
    final key = await _getApiKey();
    return key != null && key.isNotEmpty && key != 'sk-demo';
  }

  static Future<String?> _getApiKey() async {
    return (await SharedPreferences.getInstance()).getString(_apiKeyPref);
  }

  static Future<AiProvider> getProvider() async {
    final v = (await SharedPreferences.getInstance()).getString(_providerPref) ?? 'deepseek';
    return AiProvider.values.firstWhere(
      (p) => p.name == v,
      orElse: () => AiProvider.deepseek,
    );
  }

  static Future<void> setApiKey(String key, {AiProvider provider = AiProvider.deepseek}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, key);
    await prefs.setString(_providerPref, provider.name);
  }

  /// Main entry — ask AI about scan result with conversation history.
  static Future<String> askAI({
    required String disease,
    required String confidence,
    required String question,
    List<Map<String, String>> history = const [],
  }) async {
    if (await hasApiKey()) {
      try {
        final provider = await getProvider();
        return await _callApi(
          provider: provider,
          disease: disease,
          confidence: confidence,
          question: question,
          history: history,
        );
      } catch (_) {
        // Fall back to offline simulated mode
      }
    }
    return _simulatedResponse(disease, confidence, question);
  }

  static String _systemPrompt(String disease, String confidence) =>
      '''You are AgriSmartAI Assistant, an expert in rice farming and crop disease management in the Philippines. You are helping a farmer in New Bataan, Davao de Oro.

The farmer just scanned a rice leaf and the system detected: $disease with $confidence% confidence.

Answer the farmer's questions about:
- What causes this disease
- How to treat it (organic and chemical options)
- How to prevent it in the future
- When to harvest
- Whether to consult the Department of Agriculture

Be helpful, clear, and use simple language. Keep answers under 3 paragraphs.''';

  // REPLACE WITH REAL API KEY FOR PRODUCTION
  static Future<String> _callApi({
    required AiProvider provider,
    required String disease,
    required String confidence,
    required String question,
    required List<Map<String, String>> history,
  }) async {
    switch (provider) {
      case AiProvider.gemini:
        return _callGemini(disease, confidence, question, history);
      case AiProvider.groq:
        return _callOpenAiCompatible(
          baseUrl: 'https://api.groq.com/openai/v1/chat/completions',
          model: 'llama-3.3-70b-versatile',
          disease: disease,
          confidence: confidence,
          question: question,
          history: history,
        );
      case AiProvider.openai:
        return _callOpenAiCompatible(
          baseUrl: 'https://api.openai.com/v1/chat/completions',
          model: 'gpt-4o-mini',
          disease: disease,
          confidence: confidence,
          question: question,
          history: history,
        );
      case AiProvider.deepseek:
        return _callOpenAiCompatible(
          baseUrl: 'https://api.deepseek.com/v1/chat/completions',
          model: 'deepseek-chat',
          disease: disease,
          confidence: confidence,
          question: question,
          history: history,
        );
    }
  }

  static Future<String> _callOpenAiCompatible({
    required String baseUrl,
    required String model,
    required String disease,
    required String confidence,
    required String question,
    required List<Map<String, String>> history,
  }) async {
    final apiKey = await _getApiKey();
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt(disease, confidence)},
      ...history,
      {'role': 'user', 'content': question},
    ];

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'max_tokens': 450,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['choices'][0]['message']['content'] as String;
    }
    throw Exception('API error ${response.statusCode}');
  }

  static Future<String> _callGemini(
    String disease,
    String confidence,
    String question,
    List<Map<String, String>> history,
  ) async {
    final apiKey = await _getApiKey();
    final contents = <Map<String, dynamic>>[
      {
        'role': 'user',
        'parts': [
          {'text': _systemPrompt(disease, confidence)},
        ],
      },
      {
        'role': 'model',
        'parts': [
          {'text': 'Understood. I am ready to help the farmer.'},
        ],
      },
      ...history.map((m) => {
            'role': m['role'] == 'user' ? 'user' : 'model',
            'parts': [
              {'text': m['content']},
            ],
          }),
      {
        'role': 'user',
        'parts': [
          {'text': question},
        ],
      },
    ];

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': contents,
        'generationConfig': {'maxOutputTokens': 450, 'temperature': 0.7},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['candidates'][0]['content']['parts'][0]['text'] as String;
    }
    throw Exception('Gemini API error ${response.statusCode}');
  }

  /// Offline simulated AI for outline defense — rule-based keyword responses.
  static String _simulatedResponse(String disease, String confidence, String q) {
    final l = q.toLowerCase();

    if (l.contains('cause') || l.contains('why') || l.contains('ano')) {
      return _causes(disease);
    }
    if (l.contains('treat') || l.contains('gamot') || l.contains('cure') || l.contains('how do i')) {
      return _treatment(disease);
    }
    if (l.contains('spread') || l.contains('kumalat') || l.contains('other plant')) {
      return _spread(disease);
    }
    if (l.contains('harvest') || l.contains('ani') || l.contains('when')) {
      return _harvest(disease);
    }
    if (l.contains('da') || l.contains('consult') || l.contains('department')) {
      return 'Yes, I strongly recommend consulting the DA office in New Bataan or DA RFO XI Davao. '
          'Call (082) 123-4567 or visit DA Compound, Bago Oshiro, Davao City. '
          'For your $disease result ($confidence% confidence), a DA technician can verify the diagnosis.';
    }
    if (l.contains('fertilizer') || l.contains('pataba') || l.contains('npk')) {
      return _fertilizer(disease);
    }

    return 'Based on your scan ($disease, $confidence% confidence): ${_treatment(disease)} '
        'Ask me about causes, treatment, spread, harvest, or fertilizer.';
  }

  static String _causes(String d) => switch (d) {
        'Bacterial Leaf Blight' =>
          'BLB is caused by bacteria (Xanthomonas oryzae). It spreads via infected seeds, rain splash, and flooded fields.',
        'Rice Blast' =>
          'Rice blast is a fungal disease (Pyricularia oryzae). Cool nights, high humidity, and excess nitrogen promote it.',
        'Tungro' =>
          'Tungro is viral, spread by green leafhoppers. Infected plants show stunting and yellow-orange leaves.',
        _ => 'Your rice leaf appears healthy. Continue regular field monitoring.',
      };

  static String _treatment(String d) => switch (d) {
        'Bacterial Leaf Blight' =>
          'BLB is caused by bacteria. Treat by reducing nitrogen and applying potassium. Use resistant varieties like NSIC Rc 222.',
        'Rice Blast' =>
          'Rice blast is a fungal disease. Apply silicon-based fertilizers. Avoid excess nitrogen. Consult DA for fungicides.',
        'Tungro' =>
          'Tungro is viral, spread by leafhoppers. Control the vectors first. Use resistant varieties and apply balanced fertilizer.',
        _ => 'Your rice looks healthy! Continue regular care. Monitor weekly for any changes.',
      };

  static String _spread(String d) => switch (d) {
        'Bacterial Leaf Blight' =>
          'Yes, BLB spreads through rain splash and irrigation water. Isolate affected paddies.',
        'Rice Blast' => 'Yes, blast spores spread by wind and water rapidly across fields.',
        'Tungro' => 'Yes, leafhoppers carry tungro from plant to plant. Control vectors area-wide.',
        _ => 'Low risk for healthy plants, but monitor neighboring fields weekly.',
      };

  static String _harvest(String d) => switch (d) {
        'Bacterial Leaf Blight' || 'Rice Blast' =>
          'Wait 2–3 weeks after treatment, then reassess. Consult DA before harvest if severity is high.',
        'Tungro' =>
          'Severely stunted plants may not recover. Harvest healthy sections and replant resistant varieties.',
        _ => 'Harvest at 80–85% grain maturity. Your healthy crop is on track!',
      };

  static String _fertilizer(String d) => switch (d) {
        'Bacterial Leaf Blight' =>
          'Reduce nitrogen 30%. Apply MOP at 40 kg/ha. Add organic matter.',
        'Rice Blast' =>
          'Apply calcium silicate 200 kg/ha. Use balanced NPK 14-14-14.',
        'Tungro' => 'Balanced NPK with extra potassium. Use resistant variety seeds next season.',
        _ => 'Continue regular NPK 14-14-14 per DA tillering schedule.',
      };
}
