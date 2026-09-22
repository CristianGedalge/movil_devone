import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno desde .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Aviso: No se pudo cargar el archivo .env ($e). Usando valores predeterminados.");
  }

  // Initialize persistent configuration and session state
  await AppConfig.init();

  runApp(const SCMDevApp());
}

class SCMDevApp extends StatelessWidget {
  const SCMDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppConfig.instance,
      builder: (context, _) {
        final config = AppConfig.instance;
        return MaterialApp(
          title: 'SCMDev',
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
