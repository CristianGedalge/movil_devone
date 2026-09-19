import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent configuration and session state
  await AppConfig.init();

  runApp(const OneDevApp());
}

class OneDevApp extends StatelessWidget {
  const OneDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppConfig.instance,
      builder: (context, _) {
        final config = AppConfig.instance;
        return MaterialApp(
          title: 'DevOne',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: config.themeMode,
          home: config.isLoggedIn ? const HomeScreen() : const LoginScreen(),
        );
      },
    );
  }
}
