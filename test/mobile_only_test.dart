import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kilo_takip/main.dart' as app;

void main() {
  testWidgets('Tarayıcı veya masaüstü SQLite başlatmadan açıklama gösterir', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      app.main();
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Android veya iOS cihazında aç'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
