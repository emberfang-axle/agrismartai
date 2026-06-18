import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/di/providers.dart';
import '../../../shared/branding/app_brand.dart';
import '../../../shared/widgets/app_card.dart';
import '../../auth/domain/user_profile.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../da_locator/presentation/da_locator_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../scan/presentation/camera_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  final int initialTab;
  const MainShell({super.key, this.initialTab = 0});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppBrand.primary)),
      ),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Could not load profile')),
      ),
      data: (profile) {
        final user = profile ??
            UserProfile(
              id: '',
              fullName: 'Farmer',
              email: '',
              barangay: 'Batinao',
              createdAt: DateTime.now(),
            );

        final pages = [
          HomeScreen(user: user),
          const HistoryScreen(),
          const ChatScreen(),
          ProfileScreen(user: user),
        ];

        return Scaffold(
          body: IndexedStack(index: _index, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: AppBrand.accent),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history_rounded),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble_rounded),
                label: 'Chatbot',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  final UserProfile user;
  const HomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM d').format(now);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hello,', style: AppBrand.body),
                    Text(
                      user.fullName.split(' ').first,
                      style: AppBrand.heading1.copyWith(fontSize: 26),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppBrand.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppBrand.cardShadow,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wb_sunny_rounded,
                          color: AppBrand.secondary, size: 20),
                      const SizedBox(width: 6),
                      Text(dateStr, style: AppBrand.body.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _HeroCard(
              onScan: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CameraScreen()),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.05,
            ),
            delegate: SliverChildListDelegate([
              _FeatureCard(
                icon: Icons.biotech_rounded,
                title: 'Disease Detection',
                color: AppBrand.accent,
                delayMs: 100,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CameraScreen()),
                ),
              ),
              _FeatureCard(
                icon: Icons.smart_toy_rounded,
                title: 'AI Assistant',
                color: AppBrand.secondary,
                delayMs: 200,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatScreen()),
                ),
              ),
              _FeatureCard(
                icon: Icons.history_rounded,
                title: 'Scan History',
                color: const Color(0xFF1976D2),
                delayMs: 300,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
              ),
              _FeatureCard(
                icon: Icons.location_on_rounded,
                title: 'DA Office Locator',
                color: const Color(0xFF7B1FA2),
                delayMs: 400,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DaLocatorScreen()),
                ),
              ),
            ]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onScan;
  const _HeroCard({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppBrand.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppBrand.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detect Rice Diseases',
            style: AppBrand.heading2.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Detect diseases in seconds',
            style: AppBrand.body.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onScan,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: AppBrand.goldGradient,
                borderRadius: BorderRadius.circular(40),
                boxShadow: AppBrand.goldButtonShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_rounded, color: AppBrand.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Scan Rice Leaf',
                    style: AppBrand.button.copyWith(color: AppBrand.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final int delayMs;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.delayMs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        delayMs: delayMs,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppBrand.button.copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
