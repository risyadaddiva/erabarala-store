import 'package:flutter_test/flutter_test.dart';

import 'package:erabarala_store/main.dart';

void main() {
  testWidgets('App should build without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const ErabaralaStoreApp());
    expect(find.text('Kasir'), findsWidgets);
  });
}
