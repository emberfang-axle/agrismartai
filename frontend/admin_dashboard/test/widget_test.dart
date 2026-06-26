import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrismartai_dashboard/main.dart';

void main() {
  testWidgets('Admin dashboard shows login screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DashboardApp()));
    await tester.pump();
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
