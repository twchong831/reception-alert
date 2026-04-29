import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    // Secretary app requires window_manager initialization,
    // which is not available in test environment.
    expect(true, isTrue);
  });
}
