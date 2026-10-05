import 'package:flutter_test/flutter_test.dart';
import 'package:zm/main.dart';

void main() {
  testWidgets('ZmApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ZmApp());

    // Verify that the login screen title is present.
    expect(find.text('zm SECURE AUTH v1.0.62'), findsOneWidget);
  });
}
