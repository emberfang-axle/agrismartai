// AgriSmartAI — Rice Disease Detection Mobile App
// OBJECTIVE 1: Camera + gallery + local image storage + export
// OBJECTIVE 2: Simulated detection (replace with TFLite for final defense)
// OBJECTIVE 3: Disease result + fertilizer + DA referral + AI chatbot
// OBJECTIVE 4: History storage + feedback form + web dashboard reports

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/scan_model.dart';
import 'services/ai_service.dart';
import 'services/validation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStore.init();
  runApp(const AgriSmartAIApp());
}

// ─── DESIGN SYSTEM ───────────────────────────────────────────────────────────

class C {
  static const primary = Color(0xFF0B3B1F);
  static const secondary = Color(0xFFD4A017);
  static const bg = Color(0xFFFAF9F6);
  static const surface = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF1E1E1E);
  static const textLight = Color(0xFF6B6B6B);
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFD32F2F);
  static const tertiary = Color(0xFFE8F5E9);

  static const gradHero = LinearGradient(
    colors: [Color(0xFF0B3B1F), Color(0xFF1B5E20)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const gradGold = LinearGradient(colors: [Color(0xFFD4A017), Color(0xFFF5B041)]);

  static List<BoxShadow> cardShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: -5, offset: const Offset(0, 8)),
  ];
}

void haptic() => HapticFeedback.lightImpact();

Route<T> fadeSlide<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, c) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: c,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 400),
    );

// ─── DATA STORE ──────────────────────────────────────────────────────────────

class AppStore {
  static String? userName;
  static String? userEmail;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('userName');
    userEmail = prefs.getString('userEmail');
  }

  static Future<void> saveUser(String name, String email) async {
    userName = name;
    userEmail = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
  }

  static Future<void> logout() async {
    userName = null;
    userEmail = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');
    await prefs.remove('userEmail');
  }

  static Future<bool> isLoggedIn() async {
    await init();
    return userName != null;
  }

  // OBJECTIVE 4: History storage
  static Future<List<ScanRecord>> getScans() async {
    final raw = (await SharedPreferences.getInstance()).getString('scans') ?? '[]';
    return (jsonDecode(raw) as List).map((e) => ScanRecord.fromJson(e)).toList();
  }

  static Future<void> addScan(ScanRecord scan) async {
    final list = await getScans();
    list.insert(0, scan);
    await _saveScans(list);
  }

  static Future<void> deleteScan(String id) async {
    final list = await getScans();
    list.removeWhere((s) => s.id == id);
    await _saveScans(list);
  }

  static Future<void> clearScans() async {
    await (await SharedPreferences.getInstance()).remove('scans');
  }

  static Future<void> _saveScans(List<ScanRecord> list) async {
    await (await SharedPreferences.getInstance())
        .setString('scans', jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  // OBJECTIVE 1: Save images locally
  static Future<String> saveImageLocally(File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'rice_images'));
    if (!await folder.exists()) await folder.create(recursive: true);
    final dest = File(p.join(folder.path, 'leaf_${DateTime.now().millisecondsSinceEpoch}.jpg'));
    await file.copy(dest.path);
    return dest.path;
  }

  // OBJECTIVE 1: Export feature
  static Future<String> exportScansCsv() async {
    final scans = await getScans();
    final buf = StringBuffer('Date,Disease,Confidence,Fertilizer\n');
    for (final s in scans) {
      buf.writeln(
          '${DateFormat('yyyy-MM-dd HH:mm').format(s.scannedAt)},${s.disease},${(s.confidence * 100).toStringAsFixed(1)}%,"${s.fertilizerSteps.join('; ')}"');
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'agrismartai_export.csv'));
    await file.writeAsString(buf.toString());
    return file.path;
  }

  // OBJECTIVE 4: Feedback storage
  static Future<void> saveFeedback(FeedbackRecord fb) async {
    final prefs = await SharedPreferences.getInstance();
    final list = jsonDecode(prefs.getString('feedback') ?? '[]') as List;
    list.add(fb.toJson());
    await prefs.setString('feedback', jsonEncode(list));
  }

  // OBJECTIVE 4: Chat history storage (local, offline)
  static Future<void> saveChatHistory(String sessionKey, List<ChatMessage> msgs) async {
    final prefs = await SharedPreferences.getInstance();
    final all = jsonDecode(prefs.getString('chat_sessions') ?? '{}') as Map<String, dynamic>;
    all[sessionKey] = msgs.map((m) => m.toJson()).toList();
    await prefs.setString('chat_sessions', jsonEncode(all));
  }

  static Future<List<ChatMessage>> loadChatHistory(String sessionKey) async {
    final prefs = await SharedPreferences.getInstance();
    final all = jsonDecode(prefs.getString('chat_sessions') ?? '{}') as Map<String, dynamic>;
    final raw = all[sessionKey];
    if (raw == null) return [];
    return (raw as List).map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }
}

const kTips = [
  'Scan leaves in morning light for best accuracy.',
  'Hold camera 15–20 cm from the leaf.',
  'Avoid blurry photos — keep the leaf in focus.',
  'Water management prevents many rice diseases.',
  'Contact DA New Bataan if symptoms spread rapidly.',
];

Color diseaseColor(String d) => switch (d) {
      'Bacterial Leaf Blight' => const Color(0xFFFF9800),
      'Rice Blast' => const Color(0xFFD32F2F),
      'Tungro' => const Color(0xFF7B1FA2),
      _ => C.success,
    };

void toast(BuildContext c, String msg, {bool ok = true}) {
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    backgroundColor: ok ? C.success : C.error,
    content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
  ));
}

Future<bool?> confirmDialog(BuildContext c, {required String title, required String body}) =>
    showDialog<bool>(
      context: c,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(body, style: GoogleFonts.inter(height: 1.4)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: C.error),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

// ─── REUSABLE WIDGETS ────────────────────────────────────────────────────────

class AgriSmartAIApp extends StatelessWidget {
  const AgriSmartAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriSmartAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: C.bg,
        colorSchemeSeed: C.primary,
        textTheme: TextTheme(
          titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: C.textDark),
          bodyMedium: GoogleFonts.inter(color: C.textDark),
        ),
      ),
      home: const SplashPage(),
    );
  }
}

class AppCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final EdgeInsets padding;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.gradient,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final body = AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      child: Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          gradient: widget.gradient,
          color: widget.gradient == null ? C.surface : null,
          borderRadius: BorderRadius.circular(24),
          boxShadow: C.cardShadow,
        ),
        child: widget.child,
      ),
    );
    if (widget.onTap == null) return body;
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
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

class MainBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Gradient gradient;
  final Color? textColor;

  const MainBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.gradient = C.gradHero,
    this.textColor,
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
        child: Ink(
          height: 58,
          decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(40)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor ?? Colors.white),
              const SizedBox(width: 10),
              Text(label,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 16, color: textColor ?? Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class GreenHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const GreenHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                        fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              if (trailing != null) trailing!,
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
      children: List.generate(
        3,
        (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(color: C.textLight, shape: BoxShape.circle),
        )
            .animate(onPlay: (c) => c.repeat())
            .moveY(begin: 0, end: -5, duration: 400.ms, delay: (i * 120).ms)
            .then()
            .moveY(begin: -5, end: 0, duration: 400.ms),
      ),
    );
  }
}

// ─── 1. SPLASH ───────────────────────────────────────────────────────────────

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
      final loggedIn = await AppStore.isLoggedIn();
      Navigator.pushReplacement(
        context,
        fadeSlide(loggedIn ? const MainShell() : const LoginPage()),
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
              const Icon(Icons.eco_rounded, size: 90, color: C.secondary)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 1.2.seconds),
              const SizedBox(height: 24),
              Text('AgriSmartAI',
                      style: GoogleFonts.poppins(
                          fontSize: 34, fontWeight: FontWeight.w700, color: Colors.white))
                  .animate()
                  .fadeIn()
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 8),
              Text('Smart Farming, Better Harvest',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 15)),
              const Spacer(),
              Text('v1.0.0', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 2. LOGIN ────────────────────────────────────────────────────────────────

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _name = TextEditingController(text: 'Farmer Juan');
  final _email = TextEditingController(text: 'farmer@newbataan.ph');

  Future<void> _login() async {
    haptic();
    await AppStore.saveUser(_name.text.trim(), _email.text.trim());
    if (!mounted) return;
    Navigator.pushReplacement(context, fadeSlide(const MainShell()));
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
              child: AppCard(
                child: Column(
                  children: [
                    const Icon(Icons.eco_rounded, size: 56, color: C.primary),
                    const SizedBox(height: 12),
                    Text('Welcome, Farmer', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _name,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _email,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    MainBtn(label: 'START FARMING', icon: Icons.login_rounded, onTap: _login),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 3. MAIN SHELL ─────────────────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.tab = 0});
  final int tab;
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.tab;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onTab: (t) => setState(() => _tab = t)),
      const HistoryPage(),
      ChatPage(),
      const ProfilePage(),
    ];
    return Scaffold(
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          haptic();
          setState(() => _tab = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history_rounded), label: 'History'),
          NavigationDestination(icon: Icon(Icons.chat_outlined), selectedIcon: Icon(Icons.chat_rounded), label: 'Assistant'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

// ─── 4. HOME ───────────────────────────────────────────────────────────────────

class HomePage extends StatelessWidget {
  const HomePage({super.key, this.onTab});
  final ValueChanged<int>? onTab;

  @override
  Widget build(BuildContext context) {
    final name = AppStore.userName ?? 'Farmer';
    final tip = kTips[DateTime.now().day % kTips.length];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: GreenHeader(
            title: 'AgriSmartAI',
            trailing: IconButton(
              icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
              onPressed: () => Navigator.push(context, fadeSlide(const HowToScanPage())),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text('Hello, $name 👋',
                  style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700)),
              Text('New Bataan, Davao de Oro',
                  style: GoogleFonts.inter(color: C.textLight, fontSize: 13)),
              const SizedBox(height: 20),
              // OBJECTIVE 1: Scan rice leaf
              AppCard(
                gradient: C.gradHero,
                onTap: () => Navigator.push(context, fadeSlide(const CameraPage())),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SCAN RICE LEAF',
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text('Detect BLB, Blast, Tungro',
                              style: GoogleFonts.inter(color: Colors.white70)),
                        ],
                      ),
                    ),
                    const Icon(Icons.camera_alt_rounded, size: 48, color: Colors.white54),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.05, end: 0),
              const SizedBox(height: 14),
              // OBJECTIVE 3: AI Assistant
              MainBtn(
                label: 'ASK AI ASSISTANT',
                icon: Icons.smart_toy_rounded,
                gradient: C.gradGold,
                textColor: C.primary,
                onTap: () => onTab?.call(2),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MainBtn(
                      label: 'VIEW HISTORY',
                      icon: Icons.history_rounded,
                      onTap: () => onTab?.call(1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MainBtn(
                      label: 'HOW TO SCAN',
                      icon: Icons.tips_and_updates_rounded,
                      gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
                      onTap: () => Navigator.push(context, fadeSlide(const HowToScanPage())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              MainBtn(
                label: 'DA OFFICE LOCATOR',
                icon: Icons.location_on_rounded,
                gradient: const LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)]),
                onTap: () => Navigator.push(context, fadeSlide(const DaLocatorPage())),
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: C.tertiary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.lightbulb_rounded, color: C.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Farming Tip',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                          Text(tip, style: GoogleFonts.inter(fontSize: 13, color: C.textLight)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── 5. CAMERA + VALIDATION (OBJECTIVE 1) ────────────────────────────────────

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});
  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final _picker = ImagePicker();
  File? _image;
  ValidationResult? _validation;
  bool _checking = false;

  Future<void> _pick(ImageSource src) async {
    haptic();
    final picked = await _picker.pickImage(source: src, imageQuality: 75, maxWidth: 1280);
    if (picked == null || !mounted) return;
    setState(() {
      _image = File(picked.path);
      _validation = null;
      _checking = true;
    });
  }

  Future<void> _validate() async {
    if (_image == null) return;
    final result = await ValidationService.validateRiceLeaf(_image!);
    if (!mounted) return;
    setState(() {
      _validation = result;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_image != null && _validation == null && _checking) {
      _validate();
    }

    return Scaffold(
      body: Column(
        children: [
          const GreenHeader(title: 'Scan Rice Leaf'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _image == null ? _captureUi() : _previewUi(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _captureUi() {
    return Column(
      children: [
        Expanded(
          child: AppCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 220,
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(color: C.secondary, width: 3),
                    borderRadius: BorderRadius.circular(16),
                    color: C.tertiary,
                  ),
                  child: const Icon(Icons.grass_rounded, size: 64, color: C.primary),
                ),
                const SizedBox(height: 20),
                Text('Frame the rice leaf',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
                Text('Green, elongated leaf only',
                    style: GoogleFonts.inter(color: C.textLight)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _circleBtn(Icons.photo_library_rounded, 'Gallery', () => _pick(ImageSource.gallery)),
            GestureDetector(
              onTap: () => _pick(ImageSource.camera),
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: C.gradHero,
                  border: Border.all(color: C.secondary, width: 4),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 34),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.06, 1.06), duration: 1.2.seconds),
            ),
            _circleBtn(Icons.flash_on_rounded, 'Flash', () => toast(context, 'Flash toggled')),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _circleBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        haptic();
        onTap();
      },
      child: Column(
        children: [
          CircleAvatar(radius: 28, backgroundColor: C.tertiary, child: Icon(icon, color: C.primary)),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: C.textLight)),
        ],
      ),
    );
  }

  Widget _previewUi() {
    final valid = _validation?.isValid ?? false;
    return Column(
      children: [
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(_image!, fit: BoxFit.contain, width: double.infinity),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_checking)
          Shimmer.fromColors(
            baseColor: C.tertiary,
            highlightColor: Colors.white,
            child: Container(
              height: 48,
              decoration: BoxDecoration(color: C.tertiary, borderRadius: BorderRadius.circular(16)),
            ),
          )
        else if (_validation != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: valid ? C.tertiary : C.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: valid ? C.success : C.error),
            ),
            child: Text(_validation!.message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, color: valid ? C.primary : C.error)),
          ),
          if (!valid) ...[
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Validation Checks',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  _ruleRow('Green color detected', _validation!.hasGreen),
                  _ruleRow('Elongated / leaf in frame', _validation!.hasElongatedShape),
                  _ruleRow('Leaf-like texture', _validation!.hasLeafTexture),
                ],
              ),
            ),
          ],
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MainBtn(
                label: 'RETAKE',
                icon: Icons.refresh_rounded,
                gradient: const LinearGradient(colors: [C.error, Color(0xFFB71C1C)]),
                onTap: () => setState(() {
                  _image = null;
                  _validation = null;
                }),
              ),
            ),
            if (valid) ...[
              const SizedBox(width: 12),
              Expanded(
                child: MainBtn(
                  label: 'ANALYZE',
                  icon: Icons.biotech_rounded,
                  onTap: () => Navigator.push(
                    context,
                    fadeSlide(LoadingPage(image: _image!)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _ruleRow(String label, bool pass) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(pass ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 18, color: pass ? C.success : C.error),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: C.textLight)),
        ],
      ),
    );
  }
}

// ─── 6. LOADING (OBJECTIVE 2) ────────────────────────────────────────────────

class LoadingPage extends StatefulWidget {
  final File image;
  const LoadingPage({super.key, required this.image});
  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  double _progress = 0;
  late String _tip;
  Timer? _tipTimer;

  @override
  void initState() {
    super.initState();
    _tip = kTips[DateTime.now().millisecond % kTips.length];
    _tipTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() => _tip = kTips[DateTime.now().second % kTips.length]);
    });
    _analyze();
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    super.dispose();
  }

  Future<void> _analyze() async {
    for (var i = 1; i <= 25; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) setState(() => _progress = i / 25);
    }
    // OBJECTIVE 2: Simulated detection
    final result = DetectionService.simulateDetection();
    final savedPath = await AppStore.saveImageLocally(widget.image);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      fadeSlide(ResultPage(
        imagePath: savedPath,
        disease: result['disease'] as String,
        confidence: result['confidence'] as double,
        fertilizer: (result['fertilizer'] as List).cast<String>(),
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
                const Icon(Icons.eco_rounded, size: 80, color: C.secondary)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1)),
                const SizedBox(height: 24),
                Text('Analyzing rice leaf...',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 10,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(C.secondary),
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

// ─── 7. RESULT (OBJECTIVE 3) ─────────────────────────────────────────────────

class ResultPage extends StatefulWidget {
  final String imagePath;
  final String disease;
  final double confidence;
  final List<String> fertilizer;

  const ResultPage({
    super.key,
    required this.imagePath,
    required this.disease,
    required this.confidence,
    required this.fertilizer,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool _saved = false;
  double _ring = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _ring = widget.confidence);
    });
  }

  Future<void> _save() async {
    haptic();
    await AppStore.addScan(ScanRecord(
      id: 's_${DateTime.now().millisecondsSinceEpoch}',
      imagePath: widget.imagePath,
      disease: widget.disease,
      confidence: widget.confidence,
      scannedAt: DateTime.now(),
      fertilizerSteps: widget.fertilizer,
    ));
    setState(() => _saved = true);
    if (mounted) toast(context, 'Saved to history');
  }

  @override
  Widget build(BuildContext context) {
    final pct = (widget.confidence * 100).toStringAsFixed(1);
    final color = diseaseColor(widget.disease);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.file(File(widget.imagePath), fit: BoxFit.cover),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(widget.disease,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: color,
                          shadows: [Shadow(color: color.withValues(alpha: 0.4), blurRadius: 16)],
                        ))
                    .animate()
                    .fadeIn()
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: 110,
                    height: 110,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _ring),
                      duration: const Duration(milliseconds: 1000),
                      builder: (_, v, __) => Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: v,
                            strokeWidth: 10,
                            color: color,
                            backgroundColor: C.tertiary,
                          ),
                          Text('$pct%',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 20)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fertilizer Recommendations',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
                      const SizedBox(height: 14),
                      ...widget.fertilizer.asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: C.primary,
                                  child: Text('${e.key + 1}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(e.value, style: GoogleFonts.inter(height: 1.4))),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.support_agent_rounded, color: C.secondary, size: 36),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Consult DA Office',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                            Text('Verify diagnosis with a DA technician in New Bataan.',
                                style: GoogleFonts.inter(fontSize: 13, color: C.textLight)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                MainBtn(
                  label: '💬 ASK AI ABOUT THIS RESULT',
                  icon: Icons.chat_rounded,
                  gradient: C.gradGold,
                  textColor: C.primary,
                  onTap: () => Navigator.push(
                    context,
                    fadeSlide(ChatPage(
                      disease: widget.disease,
                      confidence: pct,
                    )),
                  ),
                ),
                const SizedBox(height: 12),
                MainBtn(
                  label: _saved ? 'SAVED ✓' : 'SAVE TO HISTORY',
                  icon: Icons.bookmark_rounded,
                  onTap: _saved ? () {} : _save,
                ),
                const SizedBox(height: 12),
                MainBtn(
                  label: 'NEW SCAN',
                  icon: Icons.camera_alt_rounded,
                  onTap: () {
                    Navigator.popUntil(context, (r) => r.isFirst);
                    Navigator.push(context, fadeSlide(const CameraPage()));
                  },
                ),
                const SizedBox(height: 12),
                MainBtn(
                  label: 'GIVE FEEDBACK',
                  icon: Icons.rate_review_rounded,
                  gradient: const LinearGradient(colors: [Color(0xFF455A64), Color(0xFF78909C)]),
                  onTap: () => Navigator.push(
                    context,
                    fadeSlide(FeedbackPage(disease: widget.disease)),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 8. CHATBOT (OBJECTIVE 3) ────────────────────────────────────────────────

class ChatPage extends StatefulWidget {
  final String? disease;
  final String? confidence;

  const ChatPage({super.key, this.disease, this.confidence});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <ChatMessage>[];
  bool _typing = false;
  bool _useLiveApi = false;
  late String _disease;
  late String _confidence;
  late String _sessionKey;

  static const _suggested = [
    'What causes this disease?',
    'How do I treat this?',
    'Can it spread?',
    'Should I consult DA?',
    'What fertilizer to use?',
  ];

  @override
  void initState() {
    super.initState();
    _disease = widget.disease ?? 'General Rice Farming';
    _confidence = widget.confidence ?? '—';
    _sessionKey = 'chat_${_disease}_${_confidence}';
    _initChat();
  }

  Future<void> _initChat() async {
    _useLiveApi = await AiService.hasApiKey();
    final saved = await AppStore.loadChatHistory(_sessionKey);
    if (!mounted) return;
    if (saved.isNotEmpty) {
      setState(() => _messages.addAll(saved));
    } else {
      setState(() {
        _messages.add(ChatMessage(
          role: 'ai',
          text: 'Kumusta! I am AgriSmartAI 🌾\n'
              '${widget.disease != null ? "Your scan: $_disease ($_confidence% confidence).\n" : ""}'
              'Ask me about causes, treatment, spread, harvest, or fertilizer.',
        ));
      });
    }
  }

  Future<void> _persistChat() async {
    await AppStore.saveChatHistory(_sessionKey, _messages);
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    haptic();
    setState(() {
      _messages.add(ChatMessage(role: 'user', text: text.trim()));
      _typing = true;
    });
    _input.clear();
    _scrollToEnd();
    await _persistChat();

    final history = _messages
        .where((m) => m.role == 'user' || m.role == 'ai')
        .map((m) => {'role': m.role == 'user' ? 'user' : 'assistant', 'content': m.text})
        .toList();

    final reply = await AiService.askAI(
      disease: _disease,
      confidence: _confidence,
      question: text.trim(),
      history: history.cast<Map<String, String>>(),
    );

    if (!mounted) return;
    setState(() {
      _typing = false;
      _messages.add(ChatMessage(role: 'ai', text: reply));
    });
    await _persistChat();
    _scrollToEnd();
  }

  void _clearChat() {
    haptic();
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(
        role: 'ai',
        text: 'Chat cleared. Ask me anything about $_disease.',
      ));
    });
    _persistChat();
  }

  void _scrollToEnd() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GreenHeader(
            title: 'AI Assistant',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _useLiveApi ? C.success : C.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _useLiveApi ? 'LIVE API' : 'OFFLINE',
                    style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  onPressed: _clearChat,
                ),
              ],
            ),
          ),
          if (widget.disease != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: C.tertiary,
              child: Row(
                children: [
                  const Icon(Icons.biotech_rounded, color: C.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Asking about: $_disease ($_confidence%)',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: C.primary)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_typing ? 1 : 0),
              itemBuilder: (_, i) {
                if (_typing && i == _messages.length) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _botAvatar(),
                      const SizedBox(width: 8),
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                            bottomLeft: Radius.circular(4),
                          ),
                        ),
                        child: const BouncingDots(),
                      ),
                    ],
                  );
                }
                final m = _messages[i];
                final isUser = m.role == 'user';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isUser) ...[_botAvatar(), const SizedBox(width: 8)],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: isUser ? C.gradHero : null,
                            color: isUser ? null : Colors.grey.shade100,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(isUser ? 20 : 4),
                              bottomRight: Radius.circular(isUser ? 4 : 20),
                            ),
                            boxShadow: isUser ? C.cardShadow : null,
                          ),
                          child: Text(m.text,
                              style: GoogleFonts.inter(
                                  color: isUser ? Colors.white : C.textDark, height: 1.45)),
                        ),
                      ),
                      if (isUser) const SizedBox(width: 4),
                    ],
                  ),
                ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.08, end: 0);
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: _suggested
                  .map((q) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(q, style: const TextStyle(fontSize: 12)),
                          onPressed: () => _send(q),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.mic_rounded, color: C.primary),
                  onPressed: () => toast(context, 'Voice input: coming soon'),
                ),
                Expanded(
                  child: TextField(
                    controller: _input,
                    decoration: InputDecoration(
                      hintText: 'Ask about your scan...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onSubmitted: _send,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: C.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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

  Widget _botAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: C.secondary,
      child: const Icon(Icons.eco_rounded, size: 18, color: C.primary),
    );
  }
}

// ─── 9. HISTORY (OBJECTIVE 4) ────────────────────────────────────────────────

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<ScanRecord> _scans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _scans = await AppStore.getScans();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        color: C.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: GreenHeader(title: 'Scan History')),
            if (_loading)
              SliverFillRemaining(
                child: Center(
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              )
            else if (_scans.isEmpty)
              SliverFillRemaining(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.eco_rounded, size: 72, color: C.tertiary),
                    const SizedBox(height: 12),
                    Text('No scans yet', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final s = _scans[i];
                      final file = File(s.imagePath);
                      return Dismissible(
                        key: ValueKey(s.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: C.error,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.delete_rounded, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          haptic();
                          await AppStore.deleteScan(s.id);
                          _load();
                        },
                        child: AppCard(
                          onTap: () => Navigator.push(
                            context,
                            fadeSlide(ResultPage(
                              imagePath: s.imagePath,
                              disease: s.disease,
                              confidence: s.confidence,
                              fertilizer: s.fertilizerSteps,
                            )),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: file.existsSync()
                                    ? Image.file(file, width: 64, height: 64, fit: BoxFit.cover)
                                    : Container(
                                        width: 64,
                                        height: 64,
                                        color: C.tertiary,
                                        child: const Icon(Icons.eco_rounded, color: C.primary),
                                      ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.disease,
                                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                                    Text(DateFormat('MMM d, yyyy • h:mm a').format(s.scannedAt),
                                        style: GoogleFonts.inter(fontSize: 12, color: C.textLight)),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Text('${(s.confidence * 100).toStringAsFixed(0)}%',
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700, color: C.primary)),
                                  TextButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      fadeSlide(ChatPage(
                                        disease: s.disease,
                                        confidence: (s.confidence * 100).toStringAsFixed(1),
                                      )),
                                    ),
                                    child: const Text('Ask AI', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _scans.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── 10. HOW TO SCAN ─────────────────────────────────────────────────────────

class HowToScanPage extends StatelessWidget {
  const HowToScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const GreenHeader(title: 'How to Scan'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _tipCard(Icons.check_circle_rounded, C.success, 'Good Photo',
                    'Clear green rice leaf, good lighting, leaf fills the frame, sharp focus.'),
                _tipCard(Icons.cancel_rounded, C.error, 'Bad Photo',
                    'Blurry, too dark, shows soil/tools/face, or non-green objects.'),
                _tipCard(Icons.wb_sunny_rounded, C.secondary, 'Best Time',
                    'Morning (7–9 AM) when leaves are dry and well-lit.'),
                _tipCard(Icons.straighten_rounded, C.primary, 'Distance',
                    'Hold phone 15–20 cm from the leaf. Keep camera parallel.'),
                _tipCard(Icons.grass_rounded, C.primary, 'Leaf Selection',
                    'Scan the diseased portion if visible, or a representative healthy leaf.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipCard(IconData icon, Color color, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(body, style: GoogleFonts.inter(color: C.textLight, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 11. DA LOCATOR (OBJECTIVE 3) ────────────────────────────────────────────

class DaLocatorPage extends StatelessWidget {
  const DaLocatorPage({super.key});

  Future<void> _launch(Uri u) async {
    if (!await launchUrl(u, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $u');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const GreenHeader(title: 'DA Office Locator'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                AppCard(
                  child: Column(
                    children: [
                      const Icon(Icons.map_rounded, size: 64, color: C.primary),
                      const SizedBox(height: 8),
                      Text('DA RFO XI — Davao Region',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _info(Icons.place_rounded, 'Address',
                    'DA Compound, Barangay Bago Oshiro, Davao City'),
                _info(Icons.phone_rounded, 'Phone', '(082) 123-4567'),
                _info(Icons.access_time_rounded, 'Hours', 'Mon–Fri, 8:00 AM – 5:00 PM'),
                _info(Icons.email_rounded, 'Email', 'rfo11@da.gov.ph'),
                const SizedBox(height: 16),
                MainBtn(
                  label: 'OPEN IN GOOGLE MAPS',
                  icon: Icons.map_rounded,
                  onTap: () => _launch(Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=DA+Compound+Bago+Oshiro+Davao')),
                ),
                const SizedBox(height: 12),
                AppCard(
                  gradient: const LinearGradient(colors: [C.error, Color(0xFFE57373)]),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: C.primary),
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
          ],
        ),
      ),
    );
  }
}

// ─── 12. FEEDBACK (OBJECTIVE 4) ──────────────────────────────────────────────

class FeedbackPage extends StatefulWidget {
  final String? disease;
  const FeedbackPage({super.key, this.disease});
  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  int _rating = 4;
  final _comment = TextEditingController();

  Future<void> _submit() async {
    haptic();
    await AppStore.saveFeedback(FeedbackRecord(
      rating: _rating,
      comment: '${widget.disease != null ? "[${widget.disease}] " : ""}${_comment.text.trim()}',
      submittedAt: DateTime.now(),
    ));
    if (!mounted) return;
    toast(context, 'Thank you for your feedback!');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const GreenHeader(title: 'Feedback'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('How helpful was AgriSmartAI?',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (i) => IconButton(
                        iconSize: 40,
                        onPressed: () {
                          haptic();
                          setState(() => _rating = i + 1);
                        },
                        icon: Icon(
                          i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: C.secondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _comment,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Share your experience as a farmer or technician...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const Spacer(),
                  MainBtn(label: 'SUBMIT FEEDBACK', icon: Icons.send_rounded, onTap: _submit),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 13. PROFILE + LOGOUT CONFIRMATION ───────────────────────────────────────

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _scanCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final scans = await AppStore.getScans();
    if (mounted) setState(() => _scanCount = scans.length);
  }

  Future<void> _logout() async {
    final ok = await confirmDialog(
      context,
      title: 'Logout?',
      body: 'Are you sure you want to logout? Your scan history will remain saved on this device.',
    );
    if (ok == true) {
      haptic();
      await AppStore.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, fadeSlide(const LoginPage()), (_) => false);
    }
  }

  Future<void> _export() async {
    haptic();
    final path = await AppStore.exportScansCsv();
    await Share.shareXFiles([XFile(path)], text: 'AgriSmartAI Scan Export');
    if (mounted) toast(context, 'History exported');
  }

  Future<void> _showApiKeyDialog() async {
    final keyCtrl = TextEditingController();
    var provider = AiProvider.deepseek;
    final hasKey = await AiService.hasApiKey();

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('AI API Key', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hasKey
                    ? 'API key is set. Enter a new key to replace it.'
                    : 'Outline defense uses offline AI. Add a key for live DeepSeek/Gemini/Groq.',
                style: GoogleFonts.inter(fontSize: 13, color: C.textLight),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<AiProvider>(
                value: provider,
                decoration: InputDecoration(
                  labelText: 'Provider',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: AiProvider.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase())))
                    .toList(),
                onChanged: (v) => setDlg(() => provider = v ?? AiProvider.deepseek),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  hintText: 'sk-... or Gemini key',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (keyCtrl.text.trim().isNotEmpty) {
                  await AiService.setApiKey(keyCtrl.text.trim(), provider: provider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) toast(context, 'API key saved — LIVE API enabled');
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GreenHeader(
              title: AppStore.userName ?? 'Profile',
              trailing: IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: _logout,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                AppCard(
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 32,
                        backgroundColor: C.primary,
                        child: Icon(Icons.person_rounded, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppStore.userName ?? 'Farmer',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
                            Text(AppStore.userEmail ?? '',
                                style: GoogleFonts.inter(color: C.textLight, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _stat('Scans', '$_scanCount')),
                    const SizedBox(width: 12),
                    Expanded(child: _stat('Region', 'RFO XI')),
                    const SizedBox(width: 12),
                    Expanded(child: _stat('Barangay', 'New Bataan')),
                  ],
                ),
                const SizedBox(height: 20),
                MainBtn(
                  label: 'SET AI API KEY (FINAL DEFENSE)',
                  icon: Icons.key_rounded,
                  gradient: C.gradGold,
                  textColor: C.primary,
                  onTap: _showApiKeyDialog,
                ),
                const SizedBox(height: 12),
                MainBtn(label: 'EXPORT HISTORY (CSV)', icon: Icons.download_rounded, onTap: _export),
                const SizedBox(height: 12),
                MainBtn(
                  label: 'GIVE FEEDBACK',
                  icon: Icons.rate_review_rounded,
                  gradient: C.gradGold,
                  textColor: C.primary,
                  onTap: () => Navigator.push(context, fadeSlide(const FeedbackPage())),
                ),
                const SizedBox(height: 12),
                MainBtn(
                  label: 'DA OFFICE LOCATOR',
                  icon: Icons.location_on_rounded,
                  onTap: () => Navigator.push(context, fadeSlide(const DaLocatorPage())),
                ),
                const SizedBox(height: 12),
                MainBtn(
                  label: 'LOGOUT',
                  icon: Icons.logout_rounded,
                  gradient: const LinearGradient(colors: [C.error, Color(0xFFB71C1C)]),
                  onTap: _logout,
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text('AgriSmartAI v1.0.0',
                      style: GoogleFonts.inter(color: C.textLight, fontSize: 12)),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: C.textLight)),
        ],
      ),
    );
  }
}
