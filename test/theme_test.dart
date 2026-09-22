import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movil_devone/core/config/app_config.dart';
import 'package:movil_devone/core/theme/app_theme.dart';
import 'package:movil_devone/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppConfig theme mode toggles and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final config = await AppConfig.init();

    expect(config.themeMode, ThemeMode.system);

    await config.setThemeMode(ThemeMode.dark);
    expect(config.themeMode, ThemeMode.dark);
    expect(config.isDarkMode, isTrue);

    await config.toggleTheme();
    expect(config.themeMode, ThemeMode.light);
    expect(config.isDarkMode, isFalse);

    await config.toggleTheme();
    expect(config.themeMode, ThemeMode.dark);
    expect(config.isDarkMode, isTrue);
  });

  testWidgets('SCMDevApp reflects dark theme mode', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      AppConfig.keyThemeMode: 'dark',
    });
    final config = await AppConfig.init();
    expect(config.themeMode, ThemeMode.dark);

    await tester.pumpWidget(const SCMDevApp());
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.dark);
    expect(materialApp.darkTheme, isNotNull);
    expect(materialApp.darkTheme!.brightness, Brightness.dark);
    expect(materialApp.darkTheme!.scaffoldBackgroundColor, AppTheme.backgroundDark);
  });
}
