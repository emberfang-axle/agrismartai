import '../utils/chatbot_qa.dart';
import '../utils/constants.dart';

/// Ka-Agro — offline rule-based chat with intent tracking (no repetitive replies).
class ChatbotService {
  ChatbotService({dynamic api});

  final List<String> _recentReplies = [];
  final List<String> _recentIntents = [];
  static const _maxRecent = 10;

  Future<ChatReply> ask({
    required String message,
    String? contextDisease,
    List<Map<String, String>> history = const [],
    String? userId,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return const ChatReply(
        'Palihug type ang inyong pangutana bahin sa rice diseases, abono, o DA office.',
        'ka_agro_offline',
      );
    }

    final intent = _detectIntent(trimmed);
    final base = ChatbotQA.reply(trimmed, contextDisease: contextDisease);
    final reply = _pickUniqueReply(trimmed, base, intent, contextDisease);
    _trackReply(reply, intent);
    return ChatReply(reply, 'ka_agro_offline');
  }

  String _detectIntent(String message) {
    final t = message.toLowerCase();
    if (t.contains('blast')) return 'blast';
    if (t.contains('blight') || t.contains('blb')) return 'blb';
    if (t.contains('tungro')) return 'tungro';
    if (t.contains('abono') || t.contains('fertilizer')) return 'fertilizer';
    if (t.contains('da') || t.contains('office')) return 'da';
    if (t.contains('variety') || t.contains('klase')) return 'variety';
    if (t.contains('plant') || t.contains('tanom')) return 'planting';
    if (t.contains('harvest') || t.contains('ani')) return 'harvest';
    if (t.contains('prevent') || t.contains('likay')) return 'prevent';
    if (t.contains('hello') || t.contains('kumusta')) return 'greeting';
    return 'general';
  }

  String _pickUniqueReply(
    String message,
    String base,
    String intent,
    String? contextDisease,
  ) {
    if (!_recentReplies.contains(base) && !_recentIntents.contains(intent)) {
      return base;
    }

    final variants = _variantsFor(intent, contextDisease);
    for (final v in variants) {
      if (!_recentReplies.contains(v)) return v;
    }
    return base;
  }

  List<String> _variantsFor(String intent, String? ctx) {
    switch (intent) {
      case 'blast':
        return [
          'Rice Blast (Pyricularia oryzae): diamond-shaped gray-brown lesions. Yield loss 30-70%. '
              'Treatment: Tricyclazole fungicide. Resistant: NSIC Rc 222, Rc 360.',
          'Blast spreads fast sa humid weather. Reduce nitrogen, improve spacing, apply silicon fertilizer.',
          'Para sa Blast: i-scan ang dahon, apply fungicide early, report sa DA kung severe na.',
        ];
      case 'blb':
        return [
          'Bacterial Leaf Blight: yellow-white stripes along leaf margins. Yield loss 20-50%. '
              'Reduce nitrogen, apply potassium. Resistant: NSIC Rc 222, Rc 216.',
          'BLB spreads via irrigation water. Drain fields, remove infected stubble, use resistant varieties.',
          'Para sa BLB: copper-based bactericide kung recommended sa DA, balanced NPK 14-14-14.',
        ];
      case 'tungro':
        return [
          'Tungro: viral disease, yellow-orange leaves, stunted plants. Spread by green leafhoppers.',
          'Para sa Tungro: control leafhoppers, rogue infected hills, plant NSIC Rc 222 or Rc 300.',
          'Report Tungro immediately sa DA New Bataan — (084) 123-4567.',
        ];
      case 'fertilizer':
        return [
          'Standard NPK para sa lowland rice: 90-60-60 kg/ha split sa 3 doses (basal, tillering, panicle).',
          'Magpa-soil test sa DA New Bataan para exact fertilizer recommendation.',
          'Ayaw sobra og nitrogen kung naay sakit — gamit balanced 14-14-14 with potassium.',
        ];
      case 'da':
        return [
          'DA New Bataan Agricultural Center, Poblacion. Phone: (084) 123-4567. M-F 8AM-5PM.',
          'Municipal Agriculture Office (MAO) — libre ang extension services, soil test, seed subsidy.',
          'DA Hotline: 1688. Magdala og Farmer ID (RSBSA) ug litrato sa affected leaves.',
        ];
      case 'variety':
        return [
          'Recommended: NSIC Rc 222 (blast resistant), Rc 216, Rc 360. Pangutana sa DA para sa inyong area.',
          'Para sa BLB-resistant: NSIC Rc 300. Para sa Tungro: NSIC Rc 222, Rc 300.',
          'Gamit certified seeds gikan sa DA — mas lig-on batok sa diseases.',
        ];
      case 'planting':
        return [
          'Best planting sa New Bataan: Mayo-Hunyo (wet) ug Nobyembre-Disyembre (dry).',
          'Mag-synchronize planting sa mga silingan para mas maayo ang pest control.',
        ];
      case 'harvest':
        return [
          'I-harvest kung 80-85% golden yellow ang grains — 110-120 days after planting.',
          'Harvest sa buntag, ayaw sa ulan para malikayan ang post-harvest losses.',
        ];
      case 'prevent':
        return [
          'Prevention: resistant varieties, balanced fertilizer, field sanitation, weekly monitoring.',
          'Likayi ang excess nitrogen, synchronized planting, ug certified disease-free seeds.',
        ];
      case 'greeting':
        return [ChatbotQA.greeting(contextDisease: ctx)];
      default:
        if (ctx != null && ctx != 'healthy') {
          final d = DiseaseData.byCode(ctx);
          return [
            'Bahin sa inyong ${d.name}: ${d.treatment}',
            'Para sa ${d.name} — fertilizer: ${d.fertilizer}',
            'DA referral para sa ${d.name}: ${d.daDirective}',
          ];
        }
        return [
          'Pangutana og specific: "What is Rice Blast?", "Unsa ang abono?", "Asa ang DA office?"',
          'Common diseases: BLB, Rice Blast, Tungro. I-upload ang dahon sa app para AI diagnosis.',
        ];
    }
  }

  void _trackReply(String reply, String intent) {
    _recentReplies.add(reply);
    _recentIntents.add(intent);
    if (_recentReplies.length > _maxRecent) _recentReplies.removeAt(0);
    if (_recentIntents.length > _maxRecent) _recentIntents.removeAt(0);
  }
}

class ChatReply {
  final String text;
  final String source;
  const ChatReply(this.text, this.source);
}
