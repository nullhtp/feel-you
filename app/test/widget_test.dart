import 'package:feel_you/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders an empty Scaffold', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FeelYouApp()));

    expect(find.byType(FeelYouApp), findsOneWidget);
  });
}
