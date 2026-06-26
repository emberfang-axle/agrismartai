import 'constants.dart';

/// Ka-Agro — Offline rule-based expert with priority keyword matching.
class ChatbotQA {
  ChatbotQA._();

  static const assistantName = 'Ka-Agro';

  static const List<String> suggestions = [
    'Unsa ni nga sakit?',
    'Unsa ang angay nga abono?',
    'Unsa nga klase sa humay?',
    'Asa ang DA office?',
    'What is Rice Blast?',
    'How to prevent Tungro?',
    'When to plant rice?',
    'When to harvest?',
    'How to control BPH?',
    'Free seeds from DA?',
    'RSBSA registration?',
    'Crop insurance PCIC?',
  ];

  /// Exact chip / common phrase → handler key.
  static const Map<String, String> _exactPhrases = {
    'unsa ni nga sakit?': 'disease_ask',
    'unsa ni nga sakit': 'disease_ask',
    'unsa ang angay nga abono?': 'fertilizer',
    'unsa ang angay nga abono': 'fertilizer',
    'unsa nga klase sa humay?': 'variety',
    'unsa nga klase sa humay': 'variety',
    'asa ang da office?': 'da',
    'asa ang da office': 'da',
    'what is rice blast?': 'blast_info',
    'what is rice blast': 'blast_info',
    'what is bacterial leaf blight?': 'blb_info',
    'what is bacterial leaf blight': 'blb_info',
    'what is tungro?': 'tungro_info',
    'what is tungro': 'tungro_info',
    'how to prevent tungro?': 'prevent_tungro',
    'how to prevent tungro': 'prevent_tungro',
    'when to plant rice?': 'planting_time',
    'when to plant rice': 'planting_time',
    'when to harvest?': 'harvest_time',
    'when to harvest': 'harvest_time',
    'how to control bph?': 'bph_control',
    'how to control bph': 'bph_control',
    'free seeds from da?': 'seed_subsidy',
    'free seeds from da': 'seed_subsidy',
    'rsbsa registration?': 'rsbsa',
    'rsbsa registration': 'rsbsa',
    'crop insurance pcic?': 'pcic',
    'crop insurance pcic': 'pcic',
  };

  static String greeting({String? contextDisease}) {
    if (contextDisease != null && contextDisease != 'healthy') {
      final d = DiseaseData.byCode(contextDisease);
      return 'Kumusta! Ako si $assistantName. Nakita nako nga ang inyong last scan kay '
          '${d.name}. Pangutana bahin sa abono, treatment, varieties, o DA office!';
    }
    return 'Kumusta! Ako si $assistantName — inyong rice expert sa New Bataan. '
        'Pangutana bahin sa BLB, Rice Blast, Tungro, abono, varieties, o DA office. '
        'Mas maayo mag-scan una sa dahon!';
  }

  static String reply(String message, {String? contextDisease}) {
    final text = _normalize(message);

    // 1) Exact phrase match (suggested chips).
    final exact = _exactPhrases[text];
    if (exact != null) {
      return _handleIntent(exact, contextDisease, text);
    }

    // 2) High-priority intents (specific before broad).
    if (_matches(text, ['asa ang da', 'da office', 'da compound', 'contact da', 'tawag da', 'da address'])) {
      return _daReferral(contextDisease);
    }
    if (_matches(text, ['angay nga abono', 'unsa ang abono', 'fertilizer for', 'npk', 'abono'])) {
      return _fertilizerAnswer(contextDisease, text);
    }
    if (_matches(text, ['klase sa humay', 'unsa nga klase', 'resistant variety', 'resistant varieties', 'binhi', 'seed variety'])) {
      return _varietyAnswer(contextDisease, text);
    }
    if (_matches(text, ['unsa ni nga sakit', 'unsa nga sakit', 'what disease', 'ano nga sakit', 'unsang sakit'])) {
      return _diseaseExplain(contextDisease);
    }
    if (_matches(text, ['gamot', 'treatment', 'tambal', 'treat', 'cure', 'spray'])) {
      return _treatmentAnswer(contextDisease, text);
    }
    if (_matches(text, ['prevent', 'iwas', 'unsaon paglikay', 'likay', 'avoid disease'])) {
      return _preventionAnswer(contextDisease, text);
    }
    if (_matches(text, ['rsbsa', 'farmer id', 'mag-register', 'farmer registration'])) {
      return _handleIntent('rsbsa', contextDisease, text);
    }
    if (_matches(text, ['pcic', 'crop insurance', 'palay insurance', 'farm insurance'])) {
      return _handleIntent('pcic', contextDisease, text);
    }
    if (_matches(text, ['seed subsidy', 'free seeds', 'da seeds', 'certified seeds'])) {
      return _handleIntent('seed_subsidy', contextDisease, text);
    }
    if (_matches(text, ['sure aid', 'fertilizer subsidy', 'free fertilizer'])) {
      return 'DA SURE Aid: Subsidized fertilizers para sa RSBSA-registered farmers (5 ha or less). '
          'I-update ang RSBSA sa MAO, attend DA briefing, hulata ang distribution. '
          'DA New Bataan: (084) 123-4567.';
    }

    // 3) Greetings / thanks.
    if (_matches(text, ['hello', 'hi', 'kumusta', 'kamusta', 'magandang', 'good morning'])) {
      return greeting(contextDisease: contextDisease);
    }
    if (_matches(text, ['thank', 'salamat'])) {
      return 'Walay sapayan! Padayon sa pag-monitor sa inyong uma.';
    }

    // 4) Named diseases.
    if (_matches(text, ['bacterial leaf blight', 'blb', 'xanthomonas', 'leaf blight'])) {
      return _fullDiseaseBrief(DiseaseData.byCode('bacterial_leaf_blight'));
    }
    if (_matches(text, ['rice blast', 'pyricularia', ' blast'])) {
      return _fullDiseaseBrief(DiseaseData.byCode('rice_blast'));
    }
    if (_matches(text, ['tungro', 'leafhopper', 'rtbv'])) {
      return _fullDiseaseBrief(DiseaseData.byCode('tungro'));
    }

    // 5) Scored QA pair lookup.
    var bestScore = 0.0;
    String? bestAnswer;
    for (final entry in _pairs) {
      final score = _scoreEntry(text, entry.keywords);
      if (score > bestScore) {
        bestScore = score;
        bestAnswer = entry.answer;
      }
    }
    if (bestScore >= 2.0 && bestAnswer != null) {
      return bestAnswer;
    }

    // 6) Context-only fallback if user has a scan.
    if (contextDisease != null && contextDisease != 'healthy') {
      final d = DiseaseData.byCode(contextDisease);
      return 'Bahin sa inyong ${d.name} scan: pangutana og specific — '
          '"Unsa ang abono?", "Unsa nga klase sa humay?", o "Asa ang DA office?"';
    }

    return 'Pasensya na, wala pa sa akong knowledge base ang inyong pangutana. '
        'Pwede mo i-ask ang inyong agricultural technician o mag-consult sa DA office. '
        'Try: "Unsa ni nga sakit?", "Unsa ang abono?", "Unsa nga klase sa humay?", o "Asa ang DA office?"';
  }

  static String _normalize(String raw) {
    return raw
        .toLowerCase()
        .replaceAll(RegExp(r'[?!.,;:]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _matches(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));

  static double _scoreEntry(String text, List<String> keywords) {
    var score = 0.0;
    for (final kw in keywords) {
      final k = kw.toLowerCase();
      if (text == k) {
        score += 5;
      } else if (text.contains(k)) {
        score += 2 + (k.split(' ').length * 0.5);
      }
    }
    return score;
  }

  static String _handleIntent(String intent, String? ctx, String text) {
    switch (intent) {
      case 'disease_ask':
        return _diseaseExplain(ctx);
      case 'fertilizer':
        return _fertilizerAnswer(ctx, text);
      case 'variety':
        return _varietyAnswer(ctx, text);
      case 'da':
        return _daReferral(ctx);
      case 'blast_info':
        return _fullDiseaseBrief(DiseaseData.byCode('rice_blast'));
      case 'blb_info':
        return _fullDiseaseBrief(DiseaseData.byCode('bacterial_leaf_blight'));
      case 'tungro_info':
        return _fullDiseaseBrief(DiseaseData.byCode('tungro'));
      case 'prevent_tungro':
        return 'Paglikay sa Tungro: resistant varieties (NSIC Rc 222, Rc 300), synchronized planting, '
            'control green leafhoppers early, rogue infected plants immediately.';
      case 'planting_time':
        return 'Best planting time sa New Bataan, Davao de Oro:\n'
            '• Wet season (Unahan) — Hunyo hangtod Hulyo\n'
            '• Dry season (Ulahing) — Nobyembre hangtod Disyembre\n\n'
            'Mag-synchronize sa inyong mga silingan para mas maayo ang pest ug disease control. '
            'DA New Bataan: (084) 123-4567.';
      case 'harvest_time':
        return 'I-harvest ang rice kung:\n'
            '• 80-85% sa grains nahimong golden yellow\n'
            '• 25-30 days after 50% flowering\n'
            '• Grain moisture 20-25%\n\n'
            'Harvest sa buntag para makunhoran ang shattering losses. '
            'Ayaw i-harvest sa ulan para malikayan ang post-harvest losses.';
      case 'bph_control':
        return 'Brown Planthopper (BPH) control:\n'
            '• ETL: 15 hoppers per hill\n'
            '• Drain field 3-4 days para ma-expose ang hoppers\n'
            '• Apply Buprofezin o Imidacloprid sa base sa plants\n'
            '• Gamit BPH-resistant varieties: NSIC Rc 160, Rc 222\n'
            '• Avoid broad-spectrum insecticides — nagpatay sa natural enemies';
      case 'seed_subsidy':
        return 'DA Seed Subsidy Program:\n'
            '(1) Mag-register sa Municipal Agriculture Office (MAO) sa New Bataan\n'
            '(2) Ipakita ang Farmer ID (RSBSA)\n'
            '(3) Fill out seed subsidy application form\n'
            '(4) Seeds ihatag matag planting season\n\n'
            'Requirements: RSBSA registration, valid ID, proof of land.\n'
            'DA New Bataan: (084) 123-4567.';
      case 'rsbsa':
        return 'RSBSA Registration (LIBRE):\n'
            '(1) Punta sa Municipal Agriculture Office sa New Bataan\n'
            '(2) Magdala: valid ID + land title/lease agreement\n'
            '(3) Fill out RSBSA registration form\n'
            '(4) Farmer ID makuha sulod 2-4 weeks\n\n'
            'Benefits: seed/fertilizer subsidies, PhilHealth, PCIC crop insurance, farm machinery.\n'
            'DA New Bataan: (084) 123-4567.';
      case 'pcic':
        return 'PCIC Crop Insurance:\n'
            '• Coverage: hangtod ₱30,000/ha (all-risk)\n'
            '• Premium: bililhon ra ₱500/ha para small farmers\n'
            '• Proteksyon batok sa: typhoon, flooding, drought, pests, diseases\n\n'
            'How to avail: Mag-register sa RSBSA una, apply sa MAO o DA office, '
            'mag-file og claims sulod 7 days sa crop loss.\n'
            'PCIC Hotline: (02) 8924-9026. DA New Bataan: (084) 123-4567.';
      default:
        return greeting(contextDisease: ctx);
    }
  }

  static String _diseaseExplain(String? ctx) {
    if (ctx != null && ctx != 'healthy') {
      final d = DiseaseData.byCode(ctx);
      return 'Ang inyong nadetect kay ${d.name}.\n'
          'Scientific name: ${d.scientificName}.\n'
          '${d.description}\n\n'
          'Symptoms: ${d.symptoms}';
    }
    return 'Unsa nga sakit ang imong nadetect? Pwede nimo i-ask ang specific disease sama sa '
        'Bacterial Leaf Blight, Rice Blast, o Tungro.\n\n'
        'Mas maayo mag-scan una sa dahon gamit ang AgriSmartAI para mas accurate ang tubag.';
  }

  static String _fertilizerAnswer(String? ctx, String text) {
    if (ctx != null && ctx != 'healthy') {
      final d = DiseaseData.byCode(ctx);
      return 'Para sa ${d.name}:\n${d.fertilizer}\n\n'
          'Apply every 2-3 weeks based on growth stage. Consult DA for soil test.';
    }
    if (text.contains('blight') || text.contains('blb') || text.contains('bacterial')) {
      return 'Para sa Bacterial Leaf Blight: reduce nitrogen. Apply potassium (K) ug phosphorus (P). '
          'NPK ratio: 14-14-14 with 2-4-2 split application.';
    }
    if (text.contains('blast')) {
      return 'Para sa Rice Blast: gamit og silicon-based fertilizers. Avoid excess nitrogen. '
          'NPK: 14-14-14 with added silicon. Apply every 2-3 weeks.';
    }
    if (text.contains('tungro')) {
      return 'Para sa Tungro: control leafhoppers first. Balanced NPK 14-14-14. Avoid excess nitrogen.';
    }
    return 'General rice fertilizer: 90-60-60 NPK kg/ha split into 3 doses. '
        'Magpa-soil test sa DA New Bataan para exact recommendation.';
  }

  static String _varietyAnswer(String? ctx, String text) {
    if (ctx != null && ctx != 'healthy') {
      final d = DiseaseData.byCode(ctx);
      return 'Resistant varieties para sa ${d.name}:\n'
          '${d.resistantVarieties.map((v) => '• $v').join('\n')}\n\n'
          'Pwede mag-consult sa DA New Bataan para sa certified seeds.';
    }
    return 'Ang mga resistant varieties kay NSIC Rc 222, NSIC Rc 216, ug NSIC Rc 360. '
        'Para sa Blast: NSIC Rc 222, Rc 360. Para sa BLB: NSIC Rc 300. '
        'Pwede ka mag-consult sa DA para sa seeds.';
  }

  static String _daReferral(String? ctx) {
    const office =
        'Ang DA office kay naa sa DA Compound, Barangay Bago Oshiro, Davao City.\n'
        'Phone: (082) 123-4567\n'
        'Hours: Monday-Friday, 8AM-5PM\n\n'
        'Local: Municipal Agriculture Office, New Bataan, Davao de Oro — (084) 123-4567';
    if (ctx != null && ctx != 'healthy') {
      final d = DiseaseData.byCode(ctx);
      return 'Para sa ${d.name}:\n${d.daDirective}\n\n$office';
    }
    return office;
  }

  static String _treatmentAnswer(String? ctx, String text) {
    if (ctx != null && ctx != 'healthy') {
      return 'Treatment para sa ${DiseaseData.byCode(ctx).name}:\n'
          '${DiseaseData.byCode(ctx).treatment}';
    }
    return 'General treatment: identify disease via scan, apply correct fungicide/bactericide, '
        'adjust fertilizer, consult DA technician for severe cases.';
  }

  static String _preventionAnswer(String? ctx, String text) {
    if (ctx != null && ctx != 'healthy') {
      return 'Prevention para sa ${DiseaseData.byCode(ctx).name}:\n'
          '${DiseaseData.byCode(ctx).prevention}';
    }
    return 'Prevention: resistant varieties, balanced fertilizer, field sanitation, '
        'synchronized planting, weekly monitoring.';
  }

  static String _fullDiseaseBrief(DiseaseKnowledge d) {
    return '${d.name}\nScientific: ${d.scientificName}\n\n'
        '${d.description}\n\nSymptoms: ${d.symptoms}\n\n'
        'Treatment: ${d.treatment}\n\nFertilizer: ${d.fertilizer}\n\n'
        'Resistant varieties: ${d.resistantVarieties.join(', ')}';
  }
}

class _QAPair {
  final List<String> keywords;
  final String answer;
  const _QAPair(this.keywords, this.answer);
}

const _pairs = <_QAPair>[
  // App usage
  _QAPair(['how to use', 'how to scan', 'upload photo', 'how does it work', 'agrismartai'],
      'Paggamit sa AgriSmartAI: (1) Login sa app. (2) I-tap ang Take Photo o Upload Image. (3) Kuha og litrato sa affected rice leaf. (4) Ang AI mag-analyze sa 2-5 seconds. (5) Tan-awon ang detection result, confidence score, ug fertilizer recommendations. (6) I-tap ang Chat para mangutana.'),

  // Disease spread
  _QAPair(['spread', 'contagious', 'infect other', 'neighbor', 'kumaon'],
      'Oo, ang mga rice diseases makakuha. Ang fungal diseases (blast, brown spot) kumaon pinaagi sa hangin ug tubig. Ang bacterial blight kumaon sa tubig. Ang Tungro kumaon pinaagi sa leafhopper insects. Para mapigilan: tanggala dayon ang infected plants, ayaw trabahoa ang basa nga field, liniha ang mga kagamitan.'),

  // Brown spot
  _QAPair(['brown spot', 'bipolaris', 'oval brown'],
      'Brown Spot kay fungal disease (Bipolaris oryzae), kasagaran sa nutrient-poor soils. Symptoms: oval brown spots nga may yellow halo. Treatment: Mancozeb o Propiconazole fungicide. Apply potassium ug zinc fertilizer. Gamita ang certified seeds.'),

  // Sheath blight
  _QAPair(['sheath blight', 'rhizoctonia', 'sheath'],
      'Sheath Blight (Rhizoctonia solani) nakaapekto sa leaf sheath. Symptoms: oval greenish-gray lesions sa sheath. Treatment: Validamycin o Azoxystrobin. Reduce plant density ug avoid excessive nitrogen.'),

  // General symptoms
  _QAPair(['symptoms', 'signs', 'identify', 'how to know', 'mahibaloan'],
      'Mga symptoms sa rice diseases: Blast — diamond-shaped gray-brown lesions. Bacterial Blight — yellowing gikan sa leaf tips. Tungro — yellow-orange leaves, stunted plants. Brown Spot — small oval brown spots. I-scan ang dahon gamit AgriSmartAI para instant AI diagnosis.'),

  // General treatment
  _QAPair(['treatment', 'medicine', 'fungicide', 'spray', 'chemical', 'gamot', 'tambal'],
      'Rice disease treatments: Fungal (Blast, Brown Spot) — Tricyclazole, Mancozeb, Azoxystrobin. Bacterial (Blight) — copper-based bactericide. Viral (Tungro) — kontrol ang leafhopper vector. Sundon ang label dosage ug mag-suot og protective gear.'),

  // Prevention
  _QAPair(['prevent', 'prevention', 'avoid disease', 'likay', 'iwas'],
      'Para mapigilan ang rice diseases: (1) Resistant varieties (NSIC Rc 222). (2) Crop rotation. (3) Balanced fertilizer, avoid excess nitrogen. (4) I-monitor ang field matag 5-7 days. (5) Certified disease-free seeds. (6) Proper plant spacing. (7) Konsultaha ang DA regularly.'),

  // Planting time
  _QAPair(['when to plant', 'tanom', 'planting season', 'best time plant', 'new bataan'],
      'Pinakamaayo nga oras sa pagtanom sa New Bataan: Wet season (Unahan) — Hunyo hangtod Hulyo. Dry season (Ulahing) — Nobyembre hangtod Disyembre. Mag-synchronize sa inyong mga silingan para mas maayo ang pest ug disease control. Contact DA New Bataan: (084) 123-4567.'),

  // Seed rate
  _QAPair(['seed rate', 'seeds per hectare', 'how many seeds', 'seeding rate'],
      'Seeding rates: Transplanting — 40-50 kg seeds per hectare. I-soak 24 hours unya incubate 24 hours. Direct seeding dry — 60-80 kg/ha. Direct seeding wet — 80-100 kg/ha. Transplant sa 14-21 days old (2-3 leaf stage).'),

  // Transplanting
  _QAPair(['transplant', 'transplanting', 'plant spacing', 'spacing'],
      'Rice transplanting: Best age — 14-21 days (2-3 leaves). Spacing — 20x20 cm standard, 25x25 cm preferred. 2-3 seedlings per hill. Depth — 2-3 cm. Transplant sa buntag o hapon, dili sa kainit sa adlaw.'),

  // Land preparation
  _QAPair(['land preparation', 'plow', 'harrowing', 'prepare field'],
      'Land preparation: (1) First plowing 3-4 weeks before transplanting, 20-25 cm deep. (2) Buhawi ang field 1-2 weeks after. (3) Harrowing 1-2 weeks before transplanting. (4) Leveling para uniform ang water depth. (5) Final harrowing 3-5 days before transplanting.'),

  // Varieties
  _QAPair(['variety', 'varieties', 'nsic', 'seed variety', 'which variety', 'inbred', 'hybrid'],
      'Recommended varieties: Inbred — NSIC Rc 222 (blast resistant, 110 days, 5-6 tons/ha), NSIC Rc 160 (blight tolerant), NSIC Rc 9 (drought tolerant). Hybrid — SL8 H, Mestizo, Bigante 2 (8-12 tons/ha). Pangutana ang DA kung unsa nga varieties ang resistant sa sakit sa inyong lugar.'),

  // Harvest
  _QAPair(['harvest', 'ani', 'when to harvest', 'maturity', 'ready to harvest'],
      'I-harvest ang rice kung: 80-85% sa grains nahimong golden yellow. 25-30 days after 50% flowering. Grain moisture 20-25%. Harvest sa buntag para makunhoran ang shattering losses. Ayaw i-harvest sa ulan.'),

  // Threshing
  _QAPair(['thresh', 'threshing', 'thresher'],
      'Threshing guide: I-thresh sulod sa 24 hours human ani para mapigilan ang grain deterioration. Mechanical thresher reduces losses by 5%. Target less than 2% threshing loss. DA naay thresher units available para rent. Contact DA New Bataan: (084) 123-4567.'),

  // Drying
  _QAPair(['dry rice', 'drying', 'grain moisture', 'sun dry', 'palay'],
      'Grain drying: Target moisture 14% o mas ubos para storage. Sun drying: 5-7 cm thick sa tarpaulin, i-liso matag 2 hours, 2-3 adlaw. DILI i-dry sa concrete roads. Mechanical dryer available sa DA AgriMech program.'),

  // Storage
  _QAPair(['store', 'storage', 'palay storage', 'silo', 'bag storage'],
      'Storage tips: Sealed bags, off the floor (wooden pallets). Well-ventilated room. Target moisture 14% o ubos. I-check regularly ang weevils, rats, mold. Expected shelf life sa 14% moisture: 6-12 months.'),

  // Yield
  _QAPair(['yield', 'how many bags', 'production', 'harvest yield', 'cavan'],
      'Expected yield/ha: Traditional varieties — 2-3 tons (33-50 cavans). Inbred NSIC — 4-6 tons (67-100 cavans). Hybrid — 6-10 tons (100-167 cavans). 1 ton = ~16.7 cavans sa 60 kg/cavan.'),

  // Fertilizer schedule
  _QAPair(['fertilizer schedule', 'when apply fertilizer', 'fertilizer timing'],
      'Fertilizer schedule: Basal (before planting) — 14-14-14 complete, 4 bags/ha. Tillering (20-25 DAT) — Urea 46-0-0, 2 bags/ha. Panicle initiation (45-50 DAT) — Urea, 1 bag/ha. DILI mag-apply sa flooded field — hulata ang 2-3 cm water level.'),

  // Nutrient deficiency
  _QAPair(['deficiency', 'potassium', 'phosphorus', 'zinc', 'pale leaves', 'yellow leaves'],
      'Nutrient deficiencies: Nitrogen — pale/yellow leaves, apply Urea. Phosphorus — purplish discoloration, apply Complete fertilizer. Potassium — brown leaf tips, apply MOP (0-0-60). Zinc — brown rusty spots sa young leaves, apply Zinc Sulfate 1 kg/ha foliar spray.'),

  // Organic fertilizer
  _QAPair(['organic', 'compost', 'manure', 'vermicompost'],
      'Organic fertilizers: Compost — 2-3 tons/ha 1-2 weeks before planting. Vermicompost — 1-2 tons/ha. Rice straw compost — ibalik sa field after harvest. Azolla (green manure) — 2 weeks before transplanting. Organic fertilizers nagpababa sa chemical cost by 30-50%.'),

  // Soil test
  _QAPair(['soil test', 'soil analysis', 'soil health'],
      'Soil testing: FREE para sa registered farmers sa DA Regional Field Office o PhilRice. Magdala og 500g soil mixed from 10 spots sa inyong field, 0-15 cm depth. Results: pH, N, P, K, organic matter. Contact DA New Bataan: (084) 123-4567.'),

  // Water management
  _QAPair(['water', 'irrigation', 'tubig', 'awd', 'alternate wetting'],
      'Water management (AWD): (1) Flood field 2-5 cm. (2) Paluyoa ang tubig. (3) Re-flood kung -15 cm below soil. (4) Maintain flooding 7 days before ug after heading. Benefits: 20-30% less water, less diseases, less BPH risk.'),

  // IPM / Pests
  _QAPair(['pest', 'insect', 'ipm', 'integrated pest'],
      'IPM para sa rice: (1) Cultural — synchronize planting, limpyoha ang field. (2) Biological — ampingan ang spiders, frogs, dragonflies. (3) Mechanical — hand-picking, light traps. (4) Chemical (LAST resort) — insecticide kung mag-exceed ang Economic Threshold Level.'),

  // BPH
  _QAPair(['brown planthopper', 'bph', 'planthopper', 'hopper burn'],
      'Brown Planthopper (BPH) kay pinakamapintas nga rice pest. Nagdala og hopper burn. ETL: 15 hoppers per hill. Control: Drain field 3-4 days. Apply Buprofezin o Imidacloprid sa base sa plants. Gamit ang BPH-resistant varieties (NSIC Rc 160, Rc 222).'),

  // Stem borer
  _QAPair(['stem borer', 'borer', 'deadheart', 'whitehead'],
      'Stem borer: nagdala og deadheart (vegetative) ug whitehead (reproductive). ETL: 15% deadheart o 10% whitehead. Control: Cartap Hydrochloride o Chlorantraniliprole granules. Kuhaa ang egg masses manually. Release Trichogramma pinaagi sa DA program.'),

  // Rats
  _QAPair(['rat', 'rats', 'rodent', 'mice', 'daga'],
      'Field rat control: Rats nagdala og 5-20% yield loss. Methods: (1) Community synchronized trapping. (2) Zinc phosphide bait stations. (3) Plastic sheet barriers. (4) Barn owls — 1 owl nagkaon og ~1,300 rats/year. (5) Limpyoha ang field edges.'),

  // Golden apple snail
  _QAPair(['golden apple snail', 'kuhol', 'snail', 'buhol'],
      'Golden Apple Snail (Kuhol) kay major pest sa rice. Control: (1) Hand collection sa snails ug red egg masses. (2) Transplant older seedlings (21+ days). (3) Net barriers sa irrigation inlets. (4) Release ducks 2 weeks after transplanting.'),

  // DA office
  _QAPair(['da office', 'department of agriculture', 'da new bataan', 'agricultural center'],
      'DA New Bataan Agricultural Center: Poblacion, New Bataan, Davao de Oro. Contact: (084) 123-4567. Serbisyo: Free soil analysis, seed subsidy, fertilizer subsidy (SURE Aid), farm machinery rental, extension services, farmer training. M-F 8AM-5PM. DA Hotline: 1688.'),

  // Free seeds
  _QAPair(['seed subsidy', 'free seeds', 'da seeds', 'certified seeds'],
      'DA Seed Subsidy: Paano mag-apply: (1) Mag-register sa Municipal Agriculture Office (MAO). (2) Ipakita ang Farmer ID (RSBSA). (3) Fill out seed subsidy application form. (4) Seeds ihatag matag planting season. Requirements: RSBSA registration, valid ID, proof of land.'),

  // SURE Aid
  _QAPair(['fertilizer subsidy', 'sure aid', 'free fertilizer', 'da fertilizer'],
      'DA SURE Aid Program: Subsidized fertilizers ug farm inputs para sa registered farmers. Eligible: RSBSA-registered, 5 hectares or less. How to avail: Update RSBSA sa MAO, attend DA briefing, hulata ang distribution. DA New Bataan: (084) 123-4567.'),

  // RSBSA registration
  _QAPair(['rsbsa', 'farmer id', 'farmer registration', 'register', 'mag-register'],
      'RSBSA Registration: (1) Punta sa Municipal Agriculture Office (MAO) sa New Bataan. (2) Magdala og valid ID ug land title/lease. (3) Fill out RSBSA form. (4) Makuha ang Farmer ID sulod 2-4 weeks. Benefits: seed/fertilizer subsidies, PhilHealth, PCIC crop insurance. LIBRE ang registration.'),

  // PCIC insurance
  _QAPair(['crop insurance', 'pcic', 'palay insurance', 'farm insurance'],
      'PCIC Crop Insurance: Proteksyon batok sa typhoon, flooding, drought, pests, diseases. Coverage: hangtod 30,000/ha (all-risk). Premium — subsidized para sa small farmers, bililhon ra 500/ha. Mag-file og claims sulod 7 days sa crop loss. PCIC Hotline: (02) 8924-9026. DA New Bataan: (084) 123-4567.'),

  // Identity
  _QAPair(['ka-agro', 'ka agro', 'who are you', 'kinsa ka'],
      'Ako si Ka-Agro — inyong offline AI rice expert sa AgriSmartAI para sa New Bataan, Davao de Oro! Kaya nakong motubag bahin sa rice diseases, fertilizer, pest control, harvesting, DA programs, ug uban pa.'),
];
