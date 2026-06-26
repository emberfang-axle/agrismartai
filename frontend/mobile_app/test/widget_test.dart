import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agrismartai/main.dart';

void main() {
  testWidgets('AgriSmartAI app loads splash screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AgriSmartApp()));
    await tester.pump();
    expect(find.text('AgriSmartAI'), findsOneWidget);
  });
}
