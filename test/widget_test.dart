import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:erabarala_store/main.dart';
import 'package:erabarala_store/theme/app_theme.dart';
import 'package:erabarala_store/widgets/currency_formatter.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await initializeDateFormatting('id_ID', null);
  });

  // ── Test 1 & 2: Full App Widget Tests (splash + navigation) ──
  // Combined into single test to avoid async provider bleed between tests
  group('App Startup', () {
    testWidgets('splash shows branding, correct colors, then navigates to main',
        (tester) async {
      await tester.pumpWidget(const ErabaralaStoreApp());
      // Let first frame render
      await tester.pump(const Duration(milliseconds: 50));

      // Test 1.1: Splash shows ERABARALA branding
      expect(find.text('ERABARALA'), findsOneWidget);
      expect(find.text('GAS STOVE POS'), findsOneWidget);

      // Test 1.2: Splash background is primaryYellow
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, equals(AppTheme.primaryYellow));

      // Let async DB init complete
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Test 2.1: Advance past 2s splash delay for navigation
      await tester.pump(const Duration(seconds: 1));
      // Let navigation + transition animation complete
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // MainScreen should now be visible with navigation bar items
      expect(find.text('Kasir'), findsWidgets);
    });
  });

  // ── Test 7: Theme Colors (pure unit, no widget tree needed) ──
  group('Theme', () {
    test('darkTheme primary color is #FFC107', () {
      final theme = AppTheme.darkTheme;
      expect(theme.colorScheme.primary, equals(const Color(0xFFFFC107)));
    });

    test('darkTheme brightness is dark', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, equals(Brightness.dark));
    });

    test('darkTheme scaffold background is #1E1E1E', () {
      final theme = AppTheme.darkTheme;
      expect(theme.scaffoldBackgroundColor, equals(const Color(0xFF1E1E1E)));
    });

    test('AppTheme static colors are correct', () {
      expect(AppTheme.primaryYellow, equals(const Color(0xFFFFC107)));
      expect(AppTheme.darkGray, equals(const Color(0xFF3A3A3A)));
      expect(AppTheme.cardDark, equals(const Color(0xFF383838)));
      expect(AppTheme.surfaceDark, equals(const Color(0xFF2C2C2C)));
      expect(AppTheme.accentGold, equals(const Color(0xFFFFB300)));
    });

    test('lightTheme primary color is #FFC107', () {
      final theme = AppTheme.lightTheme;
      expect(theme.colorScheme.primary, equals(const Color(0xFFFFC107)));
    });

    test('lightTheme brightness is light', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, equals(Brightness.light));
    });

    test('lightTheme scaffold background is #FAFAFA', () {
      final theme = AppTheme.lightTheme;
      expect(theme.scaffoldBackgroundColor, equals(const Color(0xFFFAFAFA)));
    });
  });

  // ── Test 8: Currency Formatter (pure unit) ──
  group('Currency Formatter', () {
    test('formats 50000 as Rp 50.000', () {
      expect(formatRupiah(50000), equals('Rp 50.000'));
    });

    test('formats 0 as Rp 0', () {
      expect(formatRupiah(0), equals('Rp 0'));
    });

    test('formats 1500000 correctly', () {
      expect(formatRupiah(1500000), equals('Rp 1.500.000'));
    });

    test('formats 999 correctly', () {
      expect(formatRupiah(999), equals('Rp 999'));
    });
  });
}
