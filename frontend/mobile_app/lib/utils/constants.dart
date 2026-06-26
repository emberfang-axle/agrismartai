import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AGRISMARTAI V2 — Premium AI Agriculture design system.

class AppConfig {
  AppConfig._();

  static const String appName = 'AgriSmartAI';
  static const String tagline = 'Smart Farming, Better Harvest';
  static const String logoAsset = 'assets/images/logo.png';
  static const String assistantName = 'Ka-Agro';
  static const String location = 'New Bataan, Davao de Oro';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );

  static const String _apiFromEnv = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_apiFromEnv.isNotEmpty) return _apiFromEnv;
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://localhost:8000';
    }
    return 'http://10.0.2.2:8000';
  }

  /// True when no backend is expected (browser demo without Python/API).
  static bool get forceOfflineDemo {
    if (const bool.fromEnvironment('OFFLINE_MODE', defaultValue: false)) {
      return true;
    }
    // Web + default URL → no API calls (avoids ERR_CONNECTION_REFUSED).
    if (kIsWeb && _apiFromEnv.isEmpty) return true;
    return false;
  }

  static bool get isSupabaseConfigured {
    final urlOk = supabaseUrl.contains('.supabase.co') &&
        !supabaseUrl.contains('YOUR_PROJECT') &&
        !supabaseUrl.contains('supabase.com/dashboard');
    final keyOk = supabaseAnonKey.isNotEmpty &&
        !supabaseAnonKey.contains('YOUR_SUPABASE') &&
        supabaseAnonKey.startsWith('eyJ');
    return urlOk && keyOk;
  }
}

class AppColors {
  AppColors._();

  // Official AGRISMARTAI palette (capstone brand)
  static const Color primary = Color(0xFF0B3B1F);
  static const Color primaryDark = Color(0xFF072A16);
  static const Color secondary = Color(0xFF1A6B3C);
  static const Color accentLime = Color(0xFFD4A017);
  static const Color accent = accentLime;
  static const Color deepGreen = primary;
  static const Color primaryLight = Color(0xFFE8F7EE);
  static const Color aiAccent = secondary;
  static const Color warmGold = Color(0xFFD4A017);
  static const Color goldLight = Color(0xFFFDE68A);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color error = danger;
  static const Color info = Color(0xFF2563EB);

  static const Color background = Color(0xFFF7FAF8);
  static const Color card = Color(0xFFFFFFFF);
  static const Color surface = card;
  static const Color surfaceVariant = Color(0xFFF0F5F2);
  static const Color border = Color(0xFFE3ECE7);
  static const Color divider = Color(0xFFE8EEEA);

  static const Color ink = Color(0xFF1A1A1A);
  static const Color muted = Color(0xFF6B7280);
  static const Color caption = Color(0xFF9CA3AF);

  static const Color cream = background;
  static const Color pageBg = background;
  static const Color softGreen = Color(0xFFECFDF3);
  static const Color aiBlue = info;
  static const Color aiBlueLight = Color(0xFFEFF6FF);
  static const Color leafGreen = secondary;

  // Dark mode — deep forest + neon green highlights
  static const Color darkBg = Color(0xFF041F12);
  static const Color darkSurface = Color(0xFF0A2E1A);
  static const Color darkCard = Color(0xFF0F3D24);
  static const Color darkInk = Color(0xFFF5FFF8);
  static const Color darkMuted = Color(0xFFA8C4B0);
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4, sm = 8, md = 16, lg = 24, xl = 32;
}

class AppRadius {
  AppRadius._();
  static const double card = 24;
  static const double button = 40;
  static const double image = 20;
  static const double modal = 32;
}

TextStyle _brandStyle({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w400,
  Color? color,
  bool heading = false,
}) {
  if (kIsWeb) {
    return TextStyle(
        fontFamily: 'Segoe UI',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color);
  }
  return heading
      ? GoogleFonts.poppins(
          fontSize: fontSize, fontWeight: fontWeight, color: color)
      : GoogleFonts.inter(
          fontSize: fontSize, fontWeight: fontWeight, color: color);
}

class AppTheme {
  AppTheme._();

  static List<BoxShadow> cardShadow([double opacity = 0.08]) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: opacity),
          blurRadius: 20,
          spreadRadius: -5,
          offset: const Offset(0, 8),
        ),
      ];

  static const goldGradient = LinearGradient(
    colors: [Color(0xFFFFE082), Color(0xFFFFB300)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const greenGradient = LinearGradient(
    colors: [Color(0xFF064420), Color(0xFF0E8A39), Color(0xFF2EBE60)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get light => _build(
        brightness: Brightness.light,
        bg: AppColors.background,
        surface: AppColors.surface,
        ink: AppColors.ink,
        muted: AppColors.muted,
        border: AppColors.border,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        bg: AppColors.darkBg,
        surface: AppColors.darkCard,
        ink: AppColors.darkInk,
        muted: AppColors.darkMuted,
        border: const Color(0xFF1A4D30),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color ink,
    required Color muted,
    required Color border,
  }) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: isDark ? AppColors.secondary : AppColors.primary,
        secondary: AppColors.accentLime,
        surface: surface,
      ),
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
    );

    final bodyFont = kIsWeb ? base.textTheme : GoogleFonts.interTextTheme(base.textTheme);
    final textTheme = bodyFont.copyWith(
      displayLarge: _brandStyle(
          fontSize: 34, fontWeight: FontWeight.w800, color: ink, heading: true),
      headlineMedium: _brandStyle(
          fontSize: 24, fontWeight: FontWeight.w700, color: ink, heading: true),
      titleLarge: _brandStyle(
          fontSize: 20, fontWeight: FontWeight.w600, color: ink, heading: true),
      titleMedium: _brandStyle(
          fontSize: 16, fontWeight: FontWeight.w600, color: ink, heading: true),
      bodyMedium: _brandStyle(fontSize: 15, color: muted),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: _brandStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: ink, heading: true),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.25),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button)),
          textStyle: _brandStyle(
              fontSize: 16, fontWeight: FontWeight.w600, heading: true),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF132015) : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.warmGold,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.ink,
      ),
    );
  }
}

class DiseaseKnowledge {
  final String code;
  final String name;
  final String scientificName;
  final String description;
  final String symptoms;
  final String treatment;
  final String fertilizer;
  final String prevention;
  final String daDirective;
  final String severity;
  final List<String> resistantVarieties;
  final Color color;

  const DiseaseKnowledge({
    required this.code,
    required this.name,
    required this.scientificName,
    required this.description,
    required this.symptoms,
    required this.treatment,
    required this.fertilizer,
    required this.prevention,
    required this.daDirective,
    required this.severity,
    required this.resistantVarieties,
    required this.color,
  });
}

class DiseaseData {
  DiseaseData._();

  static const Map<String, DiseaseKnowledge> all = {
    'bacterial_leaf_blight': DiseaseKnowledge(
      code: 'bacterial_leaf_blight',
      name: 'Bacterial Leaf Blight',
      scientificName: 'Xanthomonas oryzae pv. oryzae',
      description: 'Serious bacterial disease causing wilting and drying of leaves.',
      symptoms: 'Water-soaked yellowish stripes, gray drying tips, "kresek" wilting.',
      treatment: 'Drain fields, remove infected stubble, apply copper-based bactericide.',
      fertilizer: 'Reduce nitrogen. NPK 14-14-14 with 2-4-2 ratio. Add potassium (MOP).',
      prevention: 'Resistant varieties, certified seeds, avoid clipping leaf tips.',
      daDirective: 'Report to Municipal Agriculture Office of New Bataan.',
      severity: 'High',
      resistantVarieties: ['NSIC Rc 222', 'NSIC Rc 216', 'NSIC Rc 300'],
      color: AppColors.warning,
    ),
    'rice_blast': DiseaseKnowledge(
      code: 'rice_blast',
      name: 'Rice Blast',
      scientificName: 'Pyricularia oryzae',
      description: 'Destructive fungal disease with diamond-shaped lesions.',
      symptoms: 'Gray centers with brown margins; neck rot on panicles.',
      treatment: 'Tricyclazole fungicide at early stage, reduce nitrogen.',
      fertilizer: 'Silicon-based fertilizers. NPK 14-14-14 with added silicon. Avoid excess N.',
      prevention: 'Blast-resistant varieties, proper spacing, seed treatment.',
      daDirective: 'Coordinate with DA-New Bataan for fungicide subsidy.',
      severity: 'High',
      resistantVarieties: ['NSIC Rc 222', 'NSIC Rc 360', 'NSIC Rc 216'],
      color: AppColors.danger,
    ),
    'tungro': DiseaseKnowledge(
      code: 'tungro',
      name: 'Rice Tungro',
      scientificName: 'RTBV + RTSV (Rice Tungro Viruses)',
      description: 'Viral disease transmitted by green leafhoppers.',
      symptoms: 'Yellow-orange leaves, stunted growth, reduced tillering.',
      treatment: 'Control leafhoppers with insecticide; rogue infected plants.',
      fertilizer: 'Balanced NPK 14-14-14 after vector control. Avoid excess nitrogen.',
      prevention: 'Tungro-resistant varieties, synchronized planting.',
      daDirective: 'Notify DA-New Bataan for vector surveillance immediately.',
      severity: 'Severe',
      resistantVarieties: ['NSIC Rc 222', 'NSIC Rc 300', 'NSIC Rc 216'],
      color: Color(0xFF7B1FA2),
    ),
    'healthy': DiseaseKnowledge(
      code: 'healthy',
      name: 'Healthy Rice Leaf',
      scientificName: 'Oryza sativa',
      description: 'No disease detected. Leaf appears healthy.',
      symptoms: 'Uniform green color, no lesions or discoloration.',
      treatment: 'Continue good agricultural practices.',
      fertilizer: 'Balanced NPK 90-60-60 kg/ha based on soil test.',
      prevention: 'Field sanitation, water management, weekly monitoring.',
      daDirective: 'No referral needed. Consult DA for seasonal advisories.',
      severity: 'None',
      resistantVarieties: ['NSIC Rc 222', 'NSIC Rc 216'],
      color: AppColors.success,
    ),
  };

  static DiseaseKnowledge byCode(String code) => all[code] ?? all['healthy']!;
}
