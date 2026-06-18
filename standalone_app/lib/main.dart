import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final theme = ThemeNotifier();
  await theme.load();
  ThemeNotifierHolder.init(theme);
  runApp(AgriSmartAIApp(theme: theme));
}

// ═══════════════════════════════════════════════════════════════════════════════
// DESIGN SYSTEM — Plantix-inspired premium farming UI
// ═══════════════════════════════════════════════════════════════════════════════

class C {
  static const primary = Color(0xFF0B3B1F);
  static const primaryMid = Color(0xFF1B5E20);
  static const secondary = Color(0xFFD4A017);
  static const tertiary = Color(0xFFE8F5E9);
  static const textDark = Color(0xFF1E1E1E);
  static const textLight = Color(0xFF6B6B6B);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFD32F2F);
  static const accent = Color(0xFF43A047);
  static const surface = Color(0xFFFFFFFF);
  static const bg = Color(0xFFFAF9F6);

  static const gradHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B3B1F), Color(0xFF1B5E20), Color(0xFF052E0C)],
  );
  static const gradGold = LinearGradient(
    colors: [Color(0xFFD4A017), Color(0xFFF5B041)],
  );
  static const gradMint = LinearGradient(
    colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
  );
  static const gradSuccess = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
  );
  static const gradWarning = LinearGradient(
    colors: [Color(0xFFFF9800), Color(0xFFFFC107)],
  );
  static const gradEmergency = LinearGradient(
    colors: [Color(0xFFD32F2F), Color(0xFFE57373)],
  );

  static List<BoxShadow> depth([double y = 8, double blur = 20]) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: blur,
          spreadRadius: -5,
          offset: Offset(0, y),
        ),
      ];

  static List<BoxShadow> goldGlow() => [
        BoxShadow(
          color: secondary.withValues(alpha: 0.3),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ];
}

class ThemeNotifier extends ChangeNotifier {
  bool dark = false;
  Future<void> load() async {
    dark = (await SharedPreferences.getInstance()).getBool('dark') ?? false;
    notifyListeners();
  }

  Future<void> toggle() async {
    dark = !dark;
    await (await SharedPreferences.getInstance()).setBool('dark', dark);
    notifyListeners();
  }
}

ThemeData _theme(Brightness b, bool isDark) {
  final base = isDark ? Brightness.dark : Brightness.light;
  return ThemeData(
    useMaterial3: true,
    brightness: base,
    scaffoldBackgroundColor: isDark ? const Color(0xFF0F0F0F) : C.bg,
    colorSchemeSeed: C.primary,
    textTheme: TextTheme(
      displaySmall: GoogleFonts.poppins(
          fontWeight: FontWeight.w700, fontSize: 28, color: isDark ? Colors.white : C.textDark),
      titleLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w700, fontSize: 22, color: isDark ? Colors.white : C.textDark),
      titleMedium: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: isDark ? Colors.white70 : C.textDark),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white60 : C.textLight),
      labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
    ),
  );
}

void haptic() => HapticFeedback.lightImpact();

// ═══════════════════════════════════════════════════════════════════════════════
// DATA
// ═══════════════════════════════════════════════════════════════════════════════

class User {
  final String name, email, barangay;
  User({required this.name, required this.email, required this.barangay});
  Map<String, dynamic> toJson() => {'name': name, 'email': email, 'barangay': barangay};
  factory User.fromJson(Map<String, dynamic> j) => User(
      name: j['name'] ?? 'Farmer', email: j['email'] ?? '', barangay: j['barangay'] ?? 'New Bataan');
}

class Scan {
  final String id, imagePath, disease;
  final double confidence;
  final DateTime at;
  Scan({required this.id, required this.imagePath, required this.disease, required this.confidence, required this.at});
  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'disease': disease,
        'confidence': confidence,
        'at': at.toIso8601String(),
      };
  factory Scan.fromJson(Map<String, dynamic> j) => Scan(
        id: j['id'],
        imagePath: j['imagePath'],
        disease: j['disease'],
        confidence: (j['confidence'] as num).toDouble(),
        at: DateTime.parse(j['at']),
      );
}

class Store {
  static User? user;
  static Future<void> saveUser(User u) async {
    user = u;
    await (await SharedPreferences.getInstance())
        .setString('user', jsonEncode(u.toJson()));
  }

  static Future<User?> loadUser() async {
    final r = (await SharedPreferences.getInstance()).getString('user');
    if (r == null) return null;
    user = User.fromJson(jsonDecode(r));
    return user;
  }

  static Future<void> logout() async {
    user = null;
    await (await SharedPreferences.getInstance()).remove('user');
  }

  static Future<List<Scan>> scans() async {
    final r = (await SharedPreferences.getInstance()).getString('scans') ?? '[]';
    return (jsonDecode(r) as List).map((e) => Scan.fromJson(e)).toList();
  }

  static Future<void> addScan(Scan s) async {
    final list = await scans();
    list.insert(0, s);
    await (await SharedPreferences.getInstance())
        .setString('scans', jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  static Future<void> deleteScan(String id) async {
    final list = await scans();
    list.removeWhere((e) => e.id == id);
    await (await SharedPreferences.getInstance())
        .setString('scans', jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  static Future<void> clearScans() async =>
      (await SharedPreferences.getInstance()).remove('scans');

  static Future<String> copyImage(File f) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'scans'));
    if (!await folder.exists()) await folder.create(recursive: true);
    final dest = File(p.join(folder.path, 's_${DateTime.now().millisecondsSinceEpoch}.jpg'));
    await f.copy(dest.path);
    return dest.path;
  }

  static Future<bool> isOnboarded() async =>
      (await SharedPreferences.getInstance()).getBool('onboarded') ?? false;

  static Future<void> setOnboarded() async =>
      (await SharedPreferences.getInstance()).setBool('onboarded', true);

  static Future<bool> notificationsEnabled() async =>
      (await SharedPreferences.getInstance()).getBool('notifications') ?? true;

  static Future<void> setNotifications(bool v) async =>
      (await SharedPreferences.getInstance()).setBool('notifications', v);

  static Future<String> exportCsv() async {
    final scans = await Store.scans();
    final buf = StringBuffer('Date,Disease,Confidence,ImagePath\n');
    for (final s in scans) {
      buf.writeln(
          '${DateFormat('yyyy-MM-dd HH:mm').format(s.at)},${s.disease},${(s.confidence * 100).toStringAsFixed(1)}%,${s.imagePath}');
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'agrismartai_history.csv'));
    await file.writeAsString(buf.toString());
    return file.path;
  }
}

const kDiseases = ['Bacterial Leaf Blight', 'Rice Blast', 'Tungro', 'Healthy'];
const kTips = [
  'Water management prevents many rice diseases.',
  'Scan leaves in morning light for best accuracy.',
  'Early detection saves your harvest.',
  'Contact DA if symptoms spread rapidly.',
  'Rotate varieties to reduce disease pressure.',
  'Keep nitrogen balanced to prevent blast.',
  'Monitor leafhoppers for tungro prevention.',
  'Drain fields to reduce bacterial blight.',
];

Map<String, dynamic> detect() {
  final r = Random();
  final d = kDiseases[r.nextInt(4)];
  return {'disease': d, 'confidence': 0.70 + r.nextDouble() * 0.28};
}

String severity(double c) =>
    c >= 0.88 ? 'Severe' : c >= 0.78 ? 'Moderate' : 'Mild';

Color severityColor(String s) =>
    s == 'Severe' ? C.error : s == 'Moderate' ? C.warning : C.success;

List<String> treatment(String d) {
  switch (d) {
    case 'Bacterial Leaf Blight':
      return ['Drain flooded fields immediately', 'Reduce nitrogen fertilizer', 'Apply potassium & consult DA'];
    case 'Rice Blast':
      return ['Apply silicon-based fertilizer', 'Reduce nitrogen immediately', 'Spray fungicide per DA guide'];
    case 'Tungro':
      return ['Control green leafhopper vectors', 'Remove infected plants', 'Replant tolerant varieties'];
    default:
      return ['Continue regular NPK schedule', 'Monitor weekly for symptoms', 'Consult DA for field visit'];
  }
}

Map<String, dynamic> diseaseVisual(String d) {
  switch (d) {
    case 'Bacterial Leaf Blight':
      return {'icon': Icons.warning_rounded, 'colors': [const Color(0xFFFFF176), C.warning]};
    case 'Rice Blast':
      return {'icon': Icons.local_fire_department_rounded, 'colors': [const Color(0xFFFFAB40), C.error]};
    case 'Tungro':
      return {'icon': Icons.bug_report_rounded, 'colors': [const Color(0xFFEF9A9A), const Color(0xFFC62828)]};
    default:
      return {'icon': Icons.check_circle_rounded, 'colors': [const Color(0xFFA5D6A7), C.success]};
  }
}

Route<T> fadeSlide<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, c) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
              CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: c,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 380),
    );

// ═══════════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════════

class AgriSmartAIApp extends StatelessWidget {
  final ThemeNotifier theme;
  const AgriSmartAIApp({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: theme,
      builder: (_, __) => MaterialApp(
        title: 'AgriSmartAI',
        debugShowCheckedModeBanner: false,
        theme: _theme(Brightness.light, false),
        darkTheme: _theme(Brightness.dark, true),
        themeMode: theme.dark ? ThemeMode.dark : ThemeMode.light,
        home: const SplashPage(),
      ),
    );
  }
}

class PremiumCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.onTap,
    this.gradient,
  });

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final body = AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          gradient: widget.gradient,
          color: widget.gradient == null ? (isDark ? const Color(0xFF1A1A1A) : C.surface) : null,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05)),
          boxShadow: C.depth(8, 20),
        ),
        child: widget.child,
      ),
    );
    if (widget.onTap == null) return body;
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: () {
        haptic();
        widget.onTap!();
      },
      child: body,
    );
  }
}

class PrimaryBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Gradient? gradient;
  final Color? textColor;
  final double height;

  const PrimaryBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.gradient,
    this.textColor,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          haptic();
          onTap();
        },
        borderRadius: BorderRadius.circular(40),
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            gradient: gradient ?? C.gradHero,
            borderRadius: BorderRadius.circular(40),
            boxShadow: gradient == C.gradGold || gradient == null ? C.goldGlow() : C.depth(6, 15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor ?? Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(label,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    color: textColor ?? Colors.white,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class OutlineBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const OutlineBtn({super.key, required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          haptic();
          onTap();
        },
        borderRadius: BorderRadius.circular(40),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: C.primary, width: 2),
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: C.primary, size: 22),
              const SizedBox(width: 10),
              Text(label,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 16, color: C.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

class BouncingDots extends StatelessWidget {
  const BouncingDots({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(color: C.textLight, shape: BoxShape.circle),
        )
            .animate(onPlay: (c) => c.repeat())
            .moveY(begin: 0, end: -6, duration: 400.ms, delay: (i * 120).ms)
            .then()
            .moveY(begin: -6, end: 0, duration: 400.ms);
      }),
    );
  }
}

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  const GradientAppBar({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(110);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: C.gradHero),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Row(
            children: [
              if (Navigator.canPop(context))
                IconButton(
                  onPressed: () {
                    haptic();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                ),
              Expanded(
                child: Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              ...?actions,
            ],
          ),
        ),
      ),
    );
  }
}

void toast(BuildContext c, String msg, {bool ok = true}) {
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    backgroundColor: ok ? C.success : C.error,
    content: Row(children: [
      Icon(ok ? Icons.check_circle_rounded : Icons.error_rounded, color: Colors.white),
      const SizedBox(width: 10),
      Expanded(child: Text(msg, style: GoogleFonts.inter(color: Colors.white))),
    ]),
  ));
}

// ═══════════════════════════════════════════════════════════════════════════════
// 1. SPLASH
// ═══════════════════════════════════════════════════════════════════════════════

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final onboarded = await Store.isOnboarded();
      if (!onboarded) {
        Navigator.of(context).pushReplacement(fadeSlide(const OnboardingPage()));
        return;
      }
      final u = await Store.loadUser();
      Navigator.of(context).pushReplacement(
        fadeSlide(u == null ? const LoginPage() : const Shell()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: C.gradHero),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: C.secondary.withValues(alpha: 0.35),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.eco_rounded, size: 80, color: C.secondary),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.06, 1.06), duration: 1.2.seconds),
              const SizedBox(height: 28),
              Text('AgriSmartAI',
                  style: GoogleFonts.poppins(
                      fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white))
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 8),
              Text('Smart Farming, Better Harvest',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 15))
                  .animate()
                  .fadeIn(delay: 200.ms),
              const Spacer(),
              Shimmer.fromColors(
                baseColor: Colors.white24,
                highlightColor: Colors.white54,
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                ),
              ),
              const SizedBox(height: 40),
              Text('v2.1.0', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 1b. ONBOARDING
// ═══════════════════════════════════════════════════════════════════════════════

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _page = PageController();
  int _i = 0;

  static const _slides = [
    {
      'icon': Icons.eco_rounded,
      'title': 'Scan Rice Leaves',
      'body': 'Point your camera at any rice leaf. Our AI detects diseases in seconds.',
    },
    {
      'icon': Icons.biotech_rounded,
      'title': 'Instant Diagnosis',
      'body': 'Get disease name, severity, and a 3-step treatment plan tailored for Filipino farmers.',
    },
    {
      'icon': Icons.support_agent_rounded,
      'title': 'Connect with DA',
      'body': 'Find your nearest DA office, call experts, and protect your harvest.',
    },
  ];

  Future<void> _finish() async {
    haptic();
    await Store.setOnboarded();
    if (!mounted) return;
    final u = await Store.loadUser();
    Navigator.of(context).pushReplacement(
      fadeSlide(u == null ? const LoginPage() : const Shell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: C.gradHero),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finish,
                  child: Text('Skip',
                      style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _page,
                  itemCount: _slides.length,
                  onPageChanged: (v) => setState(() => _i = v),
                  itemBuilder: (_, i) {
                    final s = _slides[i];
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(36),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.12),
                              boxShadow: [
                                BoxShadow(
                                  color: C.secondary.withValues(alpha: 0.3),
                                  blurRadius: 40,
                                ),
                              ],
                            ),
                            child: Icon(s['icon'] as IconData, size: 72, color: C.secondary),
                          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                          const SizedBox(height: 40),
                          Text(s['title'] as String,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                  fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(height: 16),
                          Text(s['body'] as String,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                  color: Colors.white70, fontSize: 16, height: 1.5)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _i == i ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _i == i ? C.secondary : Colors.white30,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: PrimaryBtn(
                  label: _i == _slides.length - 1 ? 'GET STARTED' : 'NEXT',
                  icon: _i == _slides.length - 1 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  onTap: () {
                    if (_i < _slides.length - 1) {
                      haptic();
                      _page.nextPage(
                          duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
                    } else {
                      _finish();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. AUTH
// ═══════════════════════════════════════════════════════════════════════════════

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  Future<void> _go() async {
    haptic();
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    await Store.saveUser(User(
        name: 'Farmer Juan', email: _email.text.trim(), barangay: 'New Bataan'));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(fadeSlide(const Shell()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: C.gradHero),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: PremiumCard(
                child: Column(
                  children: [
                    const Icon(Icons.eco_rounded, size: 56, color: C.primary),
                    const SizedBox(height: 12),
                    Text('Welcome Back', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _pass,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          haptic();
                          Navigator.push(context, fadeSlide(const ForgotPage()));
                        },
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    PrimaryBtn(
                      label: 'SIGN IN',
                      icon: Icons.login_rounded,
                      onTap: _loading ? () {} : _go,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        haptic();
                        Navigator.pushReplacement(context, fadeSlide(const RegisterPage()));
                      },
                      child: const Text('Create account'),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.06, end: 0),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController(text: 'Farmer Juan');
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _brgy = TextEditingController(text: 'New Bataan');

  Future<void> _go() async {
    haptic();
    await Store.saveUser(User(
        name: _name.text.trim(), email: _email.text.trim(), barangay: _brgy.text.trim()));
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(fadeSlide(const Shell()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Create Account'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: PremiumCard(
          child: Column(
            children: [
              _field(_name, 'Full Name', Icons.person_outline_rounded),
              const SizedBox(height: 16),
              _field(_email, 'Email', Icons.email_outlined),
              const SizedBox(height: 16),
              _field(_pass, 'Password', Icons.lock_outline_rounded, obscure: true),
              const SizedBox(height: 16),
              _field(_brgy, 'Barangay', Icons.location_city_rounded),
              const SizedBox(height: 24),
              PrimaryBtn(label: 'GET STARTED', icon: Icons.arrow_forward_rounded, onTap: _go),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon, {bool obscure = false}) =>
      TextField(
        controller: c,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
}

class ForgotPage extends StatelessWidget {
  const ForgotPage({super.key});
  @override
  Widget build(BuildContext context) {
    final email = TextEditingController();
    return Scaffold(
      appBar: const GradientAppBar(title: 'Reset Password'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            PremiumCard(
              child: Column(
                children: [
                  Text('Enter your email for a reset link.',
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16))),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            PrimaryBtn(
              label: 'SEND LINK',
              icon: Icons.send_rounded,
              onTap: () {
                toast(context, 'Reset link sent (demo mode)');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. MAIN SHELL
// ═══════════════════════════════════════════════════════════════════════════════

class Shell extends StatefulWidget {
  const Shell({super.key, this.initialTab = 0});
  final int initialTab;
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late int _i;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _i = widget.initialTab;
    _pages = [
      HomePage(onNavigate: (tab) => setState(() => _i = tab)),
      const HistoryPage(),
      const ChatPage(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: _pages[_i],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : C.surface,
          boxShadow: C.depth(6, 16),
        ),
        child: NavigationBar(
          height: 76,
          selectedIndex: _i,
          onDestinationSelected: (v) {
            haptic();
            setState(() => _i = v);
          },
          backgroundColor: Colors.transparent,
          indicatorColor: C.tertiary,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: C.primary),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history_rounded, color: C.primary),
                label: 'History'),
            NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline_rounded),
                selectedIcon: Icon(Icons.chat_bubble_rounded, color: C.secondary),
                label: 'Assistant'),
            NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded, color: C.primary),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 4. HOME
// ═══════════════════════════════════════════════════════════════════════════════

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onNavigate});
  final ValueChanged<int>? onNavigate;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Scan> _recent = [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final all = await Store.scans();
    if (mounted) setState(() => _recent = all.take(3).toList());
  }

  @override
  Widget build(BuildContext context) {
    final name = Store.user?.name ?? 'Farmer';
    final tip = kTips[DateTime.now().day % kTips.length];
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: C.gradHero,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: C.gradGold),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: C.primary,
                            child: Text(name[0],
                                style: GoogleFonts.poppins(
                                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 22)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(greeting,
                                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                              Text(name,
                                  style: GoogleFonts.poppins(
                                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                              Text('📍 ${Store.user?.barangay ?? "New Bataan"}, Davao de Oro',
                                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.notifications_none_rounded,
                            color: Colors.white.withValues(alpha: 0.85), size: 26),
                      ],
                    ),
                    const SizedBox(height: 20),
                    PremiumCard(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: C.secondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.wb_sunny_rounded, color: C.secondary, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Today\'s Weather',
                                    style: GoogleFonts.inter(color: C.textLight, fontSize: 12)),
                                Text('32°C • Partly Cloudy',
                                    style: GoogleFonts.poppins(
                                        color: C.textDark, fontWeight: FontWeight.w700, fontSize: 18)),
                              ],
                            ),
                          ),
                          Text('Good for\nfield work',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.inter(color: C.textLight, fontSize: 11, height: 1.3)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scan. Detect. Protect.',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 20))
                    .animate()
                    .fadeIn()
                    .slideX(begin: -0.05, end: 0),
                const SizedBox(height: 16),
                PremiumCard(
                  gradient: C.gradHero,
                  onTap: () => Navigator.push(context, fadeSlide(const CameraPage())),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Scan Rice Leaf',
                                style: GoogleFonts.poppins(
                                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text('AI disease detection in seconds',
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: C.gradGold,
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: C.goldGlow(),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.camera_alt_rounded, color: C.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text('SCAN NOW',
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600, color: C.primary, fontSize: 14)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.grass_rounded, size: 68, color: Colors.white24),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _HubBtn(
                      icon: Icons.history_rounded,
                      label: 'History',
                      color: const Color(0xFF1565C0),
                      onTap: () => widget.onNavigate?.call(1),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _HubBtn(
                      icon: Icons.smart_toy_rounded,
                      label: 'Assistant',
                      color: C.secondary,
                      darkText: true,
                      onTap: () => widget.onNavigate?.call(2),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: _HubBtn(
                      icon: Icons.location_on_rounded,
                      label: 'DA Office',
                      color: const Color(0xFF6A1B9A),
                      onTap: () => Navigator.push(context, fadeSlide(const DaPage())),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      haptic();
                      Navigator.push(context, fadeSlide(const CameraPage()));
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: C.gradHero,
                        border: Border.all(color: C.secondary, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: C.primary.withValues(alpha: 0.35),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 40),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1.5.seconds),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_recent.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recent Scans',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recent.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final s = _recent[i];
                        final file = File(s.imagePath);
                        return PremiumCard(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: file.existsSync()
                                    ? Image.file(file, width: 56, height: 56, fit: BoxFit.cover)
                                    : Container(
                                        width: 56,
                                        height: 56,
                                        color: C.tertiary,
                                        child: const Icon(Icons.eco_rounded, color: C.primary),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(s.disease,
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600, fontSize: 13)),
                                  Text(DateFormat('MMM d').format(s.at),
                                      style: GoogleFonts.inter(fontSize: 11, color: C.textLight)),
                                  Text('${(s.confidence * 100).toStringAsFixed(0)}%',
                                      style: GoogleFonts.inter(
                                          fontSize: 11, fontWeight: FontWeight.w600, color: C.primary)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          sliver: SliverToBoxAdapter(
            child: PremiumCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: C.gradGold,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.lightbulb_rounded, color: C.primary, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Today's Farming Tip",
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(tip, style: GoogleFonts.inter(fontSize: 13, color: C.textLight, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.04, end: 0),
          ),
        ),
      ],
    );
  }
}

class _HubBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool darkText;
  final VoidCallback onTap;

  const _HubBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.darkText = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        haptic();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              boxShadow: C.depth(4, 12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600, color: C.textDark)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 5. CAMERA
// ═══════════════════════════════════════════════════════════════════════════════

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});
  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final _picker = ImagePicker();
  File? _img;
  bool _flash = false;

  Future<void> _pick(ImageSource s) async {
    haptic();
    final f = await _picker.pickImage(source: s, imageQuality: 50, maxWidth: 1280);
    if (f != null && mounted) setState(() => _img = File(f.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Scan Leaf'),
      body: _img == null ? _capture() : _preview(),
    );
  }

  Widget _capture() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: PremiumCard(
                  padding: EdgeInsets.zero,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: C.tertiary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Icon(Icons.grass_rounded, size: 80, color: C.primary),
                        ),
                      ),
                      Container(
                        width: 240,
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: C.secondary, width: 3),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Align rice leaf in frame',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _RoundBtn(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () => _pick(ImageSource.gallery),
                  ),
                  GestureDetector(
                    onTap: () => _pick(ImageSource.camera),
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: C.gradHero,
                        boxShadow: C.depth(10, 24),
                        border: Border.all(color: C.secondary, width: 4),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 36),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(begin: const Offset(1, 1), end: const Offset(1.06, 1.06), duration: 1.2.seconds),
                  ),
                  _RoundBtn(
                    icon: _flash ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    label: 'Flash',
                    onTap: () {
                      haptic();
                      setState(() => _flash = !_flash);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _preview() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: PremiumCard(
              padding: const EdgeInsets.all(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(_img!, fit: BoxFit.contain, width: double.infinity),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: C.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                    ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Row(
            children: [
              Expanded(
                child: PrimaryBtn(
                  label: 'RETAKE',
                  icon: Icons.refresh_rounded,
                  gradient: const LinearGradient(colors: [C.error, Color(0xFFB71C1C)]),
                  onTap: () => setState(() => _img = null),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PrimaryBtn(
                  label: 'USE PHOTO',
                  icon: Icons.check_rounded,
                  onTap: () => Navigator.push(
                    context,
                    fadeSlide(LoadingPage(image: _img!)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        haptic();
        onTap();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: C.tertiary,
              shape: BoxShape.circle,
              boxShadow: C.depth(4, 10),
            ),
            child: Icon(icon, color: C.primary),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: C.textLight)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 6. LOADING
// ═══════════════════════════════════════════════════════════════════════════════

class LoadingPage extends StatefulWidget {
  final File image;
  const LoadingPage({super.key, required this.image});
  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  late String _tip;
  double _progress = 0;
  int _msgIdx = 0;
  Timer? _tipTimer;

  static const _msgs = [
    'Scanning leaf...',
    'Identifying disease...',
    'Analyzing severity...',
  ];

  @override
  void initState() {
    super.initState();
    _tip = kTips[Random().nextInt(kTips.length)];
    _tipTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() => _tip = kTips[Random().nextInt(kTips.length)]);
    });
    _run();
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    super.dispose();
  }

  Future<void> _run() async {
    for (var i = 1; i <= 30; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      setState(() {
        _progress = i / 30;
        if (i == 10) _msgIdx = 1;
        if (i == 20) _msgIdx = 2;
      });
    }
    final r = detect();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      fadeSlide(ResultPage(
        image: widget.image,
        disease: r['disease'] as String,
        confidence: r['confidence'] as double,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: C.gradHero),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Spacer(),
                SizedBox(
                  height: 140,
                  child: Lottie.network(
                    'https://lottie.host/4c5c0c0e-8f3a-4e5b-9c2d-1a2b3c4d5e6f/7x8y9z.json',
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.eco_rounded,
                      size: 100,
                      color: C.secondary,
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(_msgs[_msgIdx],
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700))
                    .animate(key: ValueKey(_msgIdx))
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ShaderMask(
                    shaderCallback: (r) => C.gradGold.createShader(r),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(C.secondary),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(_tip,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.white70, height: 1.5)),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 7. RESULT
// ═══════════════════════════════════════════════════════════════════════════════

class ResultPage extends StatefulWidget {
  final File image;
  final String disease;
  final double confidence;
  const ResultPage({super.key, required this.image, required this.disease, required this.confidence});
  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool _saved = false;
  double _ring = 0;
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _ring = widget.confidence);
    });
    if (widget.disease == 'Healthy') {
      Future.delayed(const Duration(milliseconds: 600), () => _confetti.play());
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    haptic();
    final path = await Store.copyImage(widget.image);
    await Store.addScan(Scan(
      id: 's_${DateTime.now().millisecondsSinceEpoch}',
      imagePath: path,
      disease: widget.disease,
      confidence: widget.confidence,
      at: DateTime.now(),
    ));
    setState(() => _saved = true);
    if (mounted) toast(context, 'Saved to history');
  }

  void _share() {
    haptic();
    final pct = (widget.confidence * 100).toStringAsFixed(1);
    Share.share(
        'AgriSmartAI Result\n${widget.disease}\nConfidence: $pct%\nConsult DA RFO XI for verification.');
  }

  @override
  Widget build(BuildContext context) {
    final vis = diseaseVisual(widget.disease);
    final sev = severity(widget.confidence);
    final pct = (widget.confidence * 100).toStringAsFixed(1);
    final steps = treatment(widget.disease);
    final colors = vis['colors'] as List<Color>;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(widget.image, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              onPressed: () {
                haptic();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            ),
            actions: [
              IconButton(
                onPressed: _share,
                icon: const Icon(Icons.share_rounded, color: Colors.white),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: C.depth(12, 28),
                  ),
                  child: Column(
                    children: [
                      Icon(vis['icon'] as IconData, size: 48, color: Colors.white),
                      const SizedBox(height: 12),
                      Text(widget.disease,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.white.withValues(alpha: 0.5),
                                blurRadius: 20,
                              ),
                            ],
                          )),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                            sev == 'Severe'
                                ? '⚠️ HIGH SEVERITY'
                                : sev == 'Moderate'
                                    ? '⚠️ MODERATE'
                                    : '✅ LOW SEVERITY',
                            style: GoogleFonts.inter(
                                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                      ),
                    ],
                  ),
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _ring),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              value: v,
                              strokeWidth: 10,
                              backgroundColor: C.tertiary,
                              color: severityColor(sev),
                            ),
                          ),
                          Text('$pct%',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700, fontSize: 22)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                PremiumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Treatment Plan',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
                      const SizedBox(height: 16),
                      ...steps.asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: C.primary,
                                  child: Text('${e.key + 1}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                    child: Text(e.value,
                                        style: GoogleFonts.inter(height: 1.4))),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryBtn(
                  label: 'CONSULT DA OFFICE',
                  icon: Icons.support_agent_rounded,
                  gradient: C.gradGold,
                  textColor: C.primary,
                  onTap: () => Navigator.push(context, fadeSlide(const DaPage())),
                ),
                const SizedBox(height: 12),
                OutlineBtn(
                  label: _saved ? 'SAVED ✓' : 'SAVE TO HISTORY',
                  icon: Icons.bookmark_border_rounded,
                  onTap: _saved ? () {} : _save,
                ),
                const SizedBox(height: 12),
                PrimaryBtn(
                  label: 'SHARE RESULT',
                  icon: Icons.share_rounded,
                  gradient: const LinearGradient(colors: [C.accent, C.primaryMid]),
                  onTap: _share,
                ),
                const SizedBox(height: 12),
                PrimaryBtn(
                  label: 'NEW SCAN',
                  icon: Icons.camera_alt_rounded,
                  gradient: const LinearGradient(colors: [C.accent, C.primary]),
                  onTap: () {
                    haptic();
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    Navigator.push(context, fadeSlide(const CameraPage()));
                  },
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [C.secondary, C.success, Colors.white, C.primaryMid],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 8. HISTORY
// ═══════════════════════════════════════════════════════════════════════════════

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Scan> _all = [];
  List<Scan> _shown = [];
  bool _loading = true;
  String _filter = 'All';
  String _timeFilter = 'All';
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_apply);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _all = await Store.scans();
    _apply();
    if (mounted) setState(() => _loading = false);
  }

  void _apply() {
    final q = _search.text.toLowerCase();
    final now = DateTime.now();
    setState(() {
      _shown = _all.where((s) {
        final matchFilter = _filter == 'All' ||
            s.disease.toLowerCase().contains(_filter.toLowerCase().substring(0, 3));
        final matchSearch = q.isEmpty || s.disease.toLowerCase().contains(q);
        final matchTime = _timeFilter == 'All' ||
            (_timeFilter == 'Today' && s.at.day == now.day && s.at.month == now.month) ||
            (_timeFilter == 'This Week' && now.difference(s.at).inDays <= 7) ||
            (_timeFilter == 'This Month' && s.at.month == now.month && s.at.year == now.year);
        return matchFilter && matchSearch && matchTime;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: C.primary,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: C.gradHero,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Scan History',
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: C.secondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('${_all.length}',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700, color: C.primary, fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _search,
                        style: GoogleFonts.inter(),
                        decoration: InputDecoration(
                          hintText: 'Search scans...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Today', 'This Week', 'This Month', 'All']
                      .map((f) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(f, style: const TextStyle(fontSize: 12)),
                              selected: _timeFilter == f,
                              onSelected: (_) {
                                haptic();
                                setState(() => _timeFilter = f);
                                _apply();
                              },
                              selectedColor: C.secondary.withValues(alpha: 0.4),
                              checkmarkColor: C.primary,
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'BLB', 'Blast', 'Tungro', 'Healthy']
                      .map((f) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(f),
                              selected: _filter == f,
                              onSelected: (_) {
                                haptic();
                                setState(() => _filter = f);
                                _apply();
                              },
                              selectedColor: C.tertiary,
                              checkmarkColor: C.primary,
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
          _loading
              ? SliverFillRemaining(
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: 4,
                      itemBuilder: (_, __) => Container(
                        height: 90,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                )
              : _shown.isEmpty
                  ? SliverFillRemaining(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: C.tertiary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.landscape_rounded, size: 64, color: C.primary),
                          ),
                          const SizedBox(height: 16),
                          Text('No scans yet',
                              style: GoogleFonts.poppins(
                                  fontSize: 20, fontWeight: FontWeight.w600)),
                          Text('Scan a rice leaf to get started',
                              style: GoogleFonts.inter(color: C.textLight)),
                        ],
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            final s = _shown[i];
                            final file = File(s.imagePath);
                            final vis = diseaseVisual(s.disease);
                            return Dismissible(
                              key: ValueKey(s.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: C.error,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Icon(Icons.delete_rounded, color: Colors.white),
                              ),
                              onDismissed: (_) async {
                                haptic();
                                await Store.deleteScan(s.id);
                                _load();
                              },
                              child: PremiumCard(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: file.existsSync()
                                          ? Image.file(file,
                                              width: 72, height: 72, fit: BoxFit.cover)
                                          : Container(
                                              width: 72,
                                              height: 72,
                                              color: C.tertiary,
                                              child: Icon(vis['icon'] as IconData,
                                                  color: C.primary),
                                            ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s.disease,
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 4),
                                          Text(
                                              DateFormat('MMM d, yyyy • h:mm a')
                                                  .format(s.at),
                                              style: GoogleFonts.inter(
                                                  fontSize: 12, color: C.textLight)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: C.tertiary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                          '${(s.confidence * 100).toStringAsFixed(0)}%',
                                          style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              color: C.primary)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: _shown.length,
                        ),
                      ),
                    ),
        ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 9. CHAT
// ═══════════════════════════════════════════════════════════════════════════════

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _msgs = <Map<String, String>>[];
  final _input = TextEditingController();
  final _filter = TextEditingController();
  bool _typing = false;

  static const _faq = [
    {'q': 'What is rice blast?', 'a': 'Fungal disease with diamond-shaped lesions. Reduce nitrogen and apply fungicide per DA guide.'},
    {'q': 'How to prevent BLB?', 'a': 'Improve drainage, use resistant varieties, avoid excess nitrogen, apply copper bactericides.'},
    {'q': 'What is tungro?', 'a': 'Viral disease spread by leafhoppers. Control vectors and remove infected plants.'},
    {'q': 'Where is DA office?', 'a': 'DA Compound, Bago Oshiro, Davao City. Phone: (082) 123-4567.'},
    {'q': 'Best rice variety?', 'a': 'NSIC Rc 222 and Rc 160 are recommended for Mindanao.'},
  ];

  @override
  void initState() {
    super.initState();
    _msgs.add({
      'role': 'bot',
      'text': 'Kumusta! I am AgriSmartAI 🌾. Ask me about rice diseases, fertilizers, or DA services.',
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    haptic();
    setState(() {
      _msgs.add({'role': 'user', 'text': text.trim()});
      _typing = true;
    });
    _input.clear();
    await Future.delayed(const Duration(milliseconds: 900));
    final ans = _answer(text);
    if (!mounted) return;
    setState(() {
      _typing = false;
      _msgs.add({'role': 'bot', 'text': ans});
    });
  }

  String _answer(String q) {
    final l = q.toLowerCase();
    for (final f in _faq) {
      if (l.contains(f['q']!.toLowerCase().substring(0, 4))) return f['a']!;
    }
    return 'Please contact DA New Bataan at (082) 123-4567 for field verification.';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter.text.isEmpty
        ? _msgs
        : _msgs
            .where((m) => m['text']!.toLowerCase().contains(_filter.text.toLowerCase()))
            .toList();

    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: C.gradHero),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: C.secondary,
                      child: const Icon(Icons.eco_rounded, color: C.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AgriSmartAI Bot',
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontWeight: FontWeight.w700)),
                          Text('Online • Offline FAQ',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _filter,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search chat...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: _faq
                  .map((f) => ActionChip(
                        label: Text(f['q']!, style: const TextStyle(fontSize: 12)),
                        onPressed: () => _send(f['q']!),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length + (_typing ? 1 : 0),
              itemBuilder: (_, i) {
                if (_typing && i == filtered.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10, left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const BouncingDots(),
                    ),
                  );
                }
                final m = filtered[i];
                final bot = m['role'] == 'bot';
                return Align(
                  alignment: bot ? Alignment.centerLeft : Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (bot)
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: C.secondary,
                          child: const Icon(Icons.eco_rounded, size: 14, color: C.primary),
                        ),
                      if (bot) const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          margin: EdgeInsets.only(bottom: 10, left: bot ? 0 : 40, right: bot ? 40 : 0),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.72),
                          decoration: BoxDecoration(
                            gradient: bot ? null : C.gradHero,
                            color: bot ? (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2A2A2A)
                                : Colors.grey.shade100) : null,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(bot ? 4 : 20),
                              bottomRight: Radius.circular(bot ? 20 : 4),
                            ),
                            boxShadow: bot ? null : C.depth(4, 10),
                          ),
                          child: Text(m['text']!,
                              style: GoogleFonts.inter(
                                  color: bot ? C.textDark : Colors.white, height: 1.4)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => toast(context, 'Voice: enable mic in settings'),
                  icon: const Icon(Icons.mic_rounded, color: C.primary),
                ),
                Expanded(
                  child: TextField(
                    controller: _input,
                    decoration: InputDecoration(
                      hintText: 'Ask about rice farming...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onSubmitted: _send,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: C.primary,
                  radius: 26,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    onPressed: () => _send(_input.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 10. DA LOCATOR
// ═══════════════════════════════════════════════════════════════════════════════

class DaPage extends StatelessWidget {
  const DaPage({super.key});

  Future<void> _launch(Uri u) async {
    if (!await launchUrl(u, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'DA Office Locator'),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              gradient: C.gradMint,
              borderRadius: BorderRadius.circular(24),
              boxShadow: C.depth(8, 16),
            ),
            child: const Center(
              child: Icon(Icons.map_rounded, size: 64, color: C.primary),
            ),
          ),
          const SizedBox(height: 20),
          _DaTile(
            icon: Icons.place_rounded,
            title: 'Address',
            value: 'DA Compound, Barangay Bago Oshiro, Davao City',
            action: Icons.copy_rounded,
            onAction: () {
              haptic();
              Clipboard.setData(const ClipboardData(
                  text: 'DA Compound, Barangay Bago Oshiro, Davao City'));
              toast(context, 'Address copied');
            },
          ),
          _DaTile(
            icon: Icons.phone_rounded,
            title: 'Phone',
            value: '(082) 123-4567',
            action: Icons.call_rounded,
            onAction: () {
              haptic();
              _launch(Uri.parse('tel:0821234567'));
            },
          ),
          _DaTile(
            icon: Icons.access_time_rounded,
            title: 'Hours',
            value: 'Monday–Friday, 8:00 AM – 5:00 PM',
          ),
          _DaTile(
            icon: Icons.email_rounded,
            title: 'Email',
            value: 'rfo11@da.gov.ph',
            action: Icons.send_rounded,
            onAction: () {
              haptic();
              _launch(Uri.parse('mailto:rfo11@da.gov.ph'));
            },
          ),
          const SizedBox(height: 16),
          PrimaryBtn(
            label: 'OPEN IN GOOGLE MAPS',
            icon: Icons.map_rounded,
            onTap: () {
              haptic();
              _launch(Uri.parse(
                  'https://www.google.com/maps/search/?api=1&query=DA+Compound+Bago+Oshiro+Davao+City'));
            },
          ),
          const SizedBox(height: 16),
          PremiumCard(
            gradient: C.gradEmergency,
            child: Row(
              children: [
                const Icon(Icons.emergency_rounded, color: Colors.white, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Emergency Hotline',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700, color: Colors.white)),
                      Text('DA Hotline: 1688 (24/7)',
                          style: GoogleFonts.inter(color: Colors.white70)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    haptic();
                    _launch(Uri.parse('tel:1688'));
                  },
                  icon: const Icon(Icons.call_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PrimaryBtn(
            label: 'CALL NOW',
            icon: Icons.phone_in_talk_rounded,
            gradient: C.gradEmergency,
            onTap: () {
              haptic();
              _launch(Uri.parse('tel:0821234567'));
            },
          ),
        ],
      ),
    );
  }
}

class _DaTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final IconData? action;
  final VoidCallback? onAction;

  const _DaTile({
    required this.icon,
    required this.title,
    required this.value,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: C.primary, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  Text(value, style: GoogleFonts.inter(color: C.textLight, fontSize: 13)),
                ],
              ),
            ),
            if (action != null)
              IconButton(
                onPressed: onAction,
                icon: Icon(action, color: C.secondary),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 11. PROFILE
// ═══════════════════════════════════════════════════════════════════════════════

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _scans = 0;
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _load();
    Store.notificationsEnabled().then((v) {
      if (mounted) setState(() => _notifications = v);
    });
  }

  Future<void> _load() async {
    final s = await Store.scans();
    if (mounted) setState(() => _scans = s.length);
  }

  Future<void> _export() async {
    haptic();
    final path = await Store.exportCsv();
    await Share.shareXFiles([XFile(path)], text: 'AgriSmartAI Scan History Export');
    if (mounted) toast(context, 'History exported');
  }

  @override
  Widget build(BuildContext context) {
    final user = Store.user;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(gradient: C.gradHero),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: C.gradGold,
                            ),
                            child: const CircleAvatar(
                              radius: 48,
                              backgroundColor: C.primary,
                              child: Icon(Icons.person_rounded, size: 48, color: Colors.white),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: C.secondary,
                              child: const Icon(Icons.edit_rounded, size: 16, color: C.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(user?.name ?? 'Farmer',
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                      Text(user?.email ?? '', style: GoogleFonts.inter(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Expanded(child: _StatCard('Scans', '$_scans', Icons.camera_alt_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard('Detected', '${_scans > 0 ? _scans - 1 : 0}', Icons.biotech_rounded)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard('Streak', '12d', Icons.local_fire_department_rounded)),
                  ],
                ),
                const SizedBox(height: 28),
                Text('Preferences',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                _SettingTile(
                  icon: Icons.dark_mode_rounded,
                  title: 'Dark Mode',
                  trailing: Switch(
                    value: Theme.of(context).brightness == Brightness.dark,
                    activeColor: C.primary,
                    onChanged: (_) {
                      haptic();
                      ThemeNotifierHolder.toggle(context);
                    },
                  ),
                ),
                _SettingTile(
                  icon: Icons.notifications_rounded,
                  title: 'Daily Farming Tips',
                  subtitle: 'Weekly summary & tips',
                  trailing: Switch(
                    value: _notifications,
                    activeColor: C.primary,
                    onChanged: (v) async {
                      haptic();
                      await Store.setNotifications(v);
                      setState(() => _notifications = v);
                      if (mounted) toast(context, v ? 'Notifications enabled' : 'Notifications off');
                    },
                  ),
                ),
                _SettingTile(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () => toast(context, 'Filipino coming soon'),
                ),
                const SizedBox(height: 20),
                Text('Data',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                _SettingTile(
                  icon: Icons.download_rounded,
                  title: 'Export History (CSV)',
                  onTap: _export,
                ),
                _SettingTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Clear History',
                  onTap: () async {
                    haptic();
                    await Store.clearScans();
                    await _load();
                    if (mounted) toast(context, 'History cleared');
                  },
                ),
                const SizedBox(height: 20),
                Text('Account',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 12),
                _SettingTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Tutorial',
                  onTap: () => Navigator.push(context, fadeSlide(const OnboardingPage())),
                ),
                _SettingTile(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  onTap: () async {
                    haptic();
                    await Store.logout();
                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                        fadeSlide(const LoginPage()), (_) => false);
                  },
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text('AgriSmartAI v2.1.0',
                      style: GoogleFonts.inter(color: C.textLight, fontSize: 12)),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// Theme holder for dark mode from anywhere
class ThemeNotifierHolder {
  static ThemeNotifier? _n;
  static void init(ThemeNotifier n) => _n = n;
  static void toggle(BuildContext c) {
    _n?.toggle();
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatCard(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: C.primary),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 20)),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: C.textLight)),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: C.primary),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded) : null),
      ),
    );
  }
}
