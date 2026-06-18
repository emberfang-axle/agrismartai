import 'package:flutter_test/flutter_test.dart';
import 'package:admin_web_dashboard/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AdminApp());
  });
}
