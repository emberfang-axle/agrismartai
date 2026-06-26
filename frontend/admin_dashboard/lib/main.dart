import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap.dart';
import 'screens/app_shell.dart';
import 'theme/app_theme.dart';

void main() {
  bootstrapApp();
  runApp(const ProviderScope(child: DashboardApp()));
}

class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriSmartAI Admin',
      debugShowCheckedModeBanner: false,
      theme: DashboardTheme.build(),
      home: const AppShell(),
    );
  }
}
