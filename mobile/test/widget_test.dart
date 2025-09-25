// Basic smoke test for app boot
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:solnova_mobile/main.dart';

void main() {
  testWidgets('App boots to LoginScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SolnovaApp()));
    expect(find.text('SOLNOVA'), findsOneWidget);
  });
}
