import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt24_shared/receipt24_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleNotifier', () {
    test('setLocale persists to shared preferences', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = LocaleNotifier();
      await Future<void>.delayed(Duration.zero);

      await notifier.setLocale('fr');
      expect(notifier.state, 'fr');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('receipt24_locale'), 'fr');
    });
  });

  group('ThemeModeNotifier', () {
    test('setThemeMode persists dark mode', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = ThemeModeNotifier();
      await Future<void>.delayed(Duration.zero);

      await notifier.setThemeMode(ThemeMode.dark);
      expect(notifier.state, ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('receipt24_theme_mode'), 'dark');
    });
  });
}
