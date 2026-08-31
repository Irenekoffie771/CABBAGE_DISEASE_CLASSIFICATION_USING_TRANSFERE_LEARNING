import 'package:flutter_test/flutter_test.dart';
import 'package:cabage_ai/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CabbageDoctorApp());

    // Verify that our app name is present
    expect(find.text('Cabbage Doctor'), findsOneWidget);
  });
}
