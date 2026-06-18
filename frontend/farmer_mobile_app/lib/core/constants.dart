class AppColors {
  static const primary = 0xFF0B3B1F;
  static const secondary = 0xFFD4A017;
  static const accent = 0xFF43A047;
  static const background = 0xFFFAF9F6;
  static const surface = 0xFFFFFFFF;
  static const text = 0xFF1A1A1A;
}

class AppStrings {
  static const appName = 'AgriSmartAI';
  static const tagline = 'Smart Farming, Better Harvest';

  static const daName = 'DA Regional Field Office XI';
  static const daAddress = 'DA Compound, Bago Oshiro, Davao City';
  static const daPhone = '(082) 123-4567';
  static const daHours = 'Mon–Fri, 8AM–5PM';
  static const daMapsUrl =
      'https://www.google.com/maps/search/DA+Compound+Bago+Oshiro+Davao+City';
}

class AppConstants {
  static const diseases = ['BLB', 'Blast', 'Tungro', 'Healthy'];

  static const diseaseFullNames = {
    'BLB': 'Bacterial Leaf Blight',
    'Blast': 'Rice Blast',
    'Tungro': 'Tungro',
    'Healthy': 'Healthy',
  };

  static const barangays = [
    'Batinao',
    'New Bataan',
    'Compostela',
    'Andap',
    'Bantacan',
    'Cambagang',
    'Casulog',
    'Cogon',
    'Comintal',
    'Do-ol',
    'Dulyan',
    'Guinsaugon',
    'Linao',
    'Mabayong',
    'Maitum',
    'Malaong',
    'Manipongol',
    'Manat',
    'New Albay',
    'New Visayas',
    'Pangutosan',
    'Poblacion',
    'San Jose',
    'San Roque',
    'Tandawan',
  ];

  static const farmingTips = [
    '🌾 Water rice fields 2–3 inches deep during tillering stage.',
    '🌱 Apply nitrogen fertilizer in split doses for better yield.',
    '🐛 Scout fields weekly for leafhoppers — they spread Tungro.',
    '💧 Drain fields before applying fungicide for Rice Blast.',
    '🧪 Test soil pH every season — rice thrives at 5.5–6.5.',
    '🌿 Remove infected plants immediately to stop disease spread.',
    '☀️ Morning scans give the best leaf images for AI detection.',
  ];

  static const suggestedQuestions = [
    'What causes this disease?',
    'How do I treat this?',
    'Can it spread?',
    'Should I consult DA?',
  ];
}
