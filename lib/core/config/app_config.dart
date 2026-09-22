import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AuthType {
  none,
  bearer,
  basic,
}

class AppConfig extends ChangeNotifier {
  static const String keyBaseUrl = 'onedev_base_url';
  static const String keyAuthType = 'onedev_auth_type';
  static const String keyToken = 'onedev_token';
  static const String keyUsername = 'onedev_username';
  static const String keyPassword = 'onedev_password';
  static const String keyIsLoggedIn = 'onedev_is_logged_in';
  static const String keyUserDisplayName = 'onedev_user_display_name';
  static const String keyUserId = 'onedev_user_id';
  static const String keyThemeMode = 'onedev_theme_mode';

  // URL predeterminada del backend leída desde .env (o fallback en producción)
  static String get defaultBackendUrl {
    final envUrl = dotenv.isInitialized ? dotenv.env['SCMDEV_BACKEND_URL'] : null;
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    return const String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: 'https://scmdev.erikaguilarchuviru.dev/~api',
    );
  }
  static const String defaultDeployedUrl = 'https://scmdev.erikaguilarchuviru.dev/~api';
  static const String defaultLocalIpUrl = 'http://192.168.100.50:6610/~api';
  static const String defaultEmulatorUrl = 'http://10.0.2.2:6610/~api';
  static const String defaultLocalhostUrl = 'http://localhost:6610/~api';

  late SharedPreferences _prefs;

  String _baseUrl = defaultDeployedUrl;
  AuthType _authType = AuthType.basic;
  String _token = '';
  String _username = '';
  String _password = '';
  bool _isLoggedIn = false;
  String _userDisplayName = '';
  int _userId = 0;
  ThemeMode _themeMode = ThemeMode.system;

  String get baseUrl => _baseUrl;
  AuthType get authType => _authType;
  String get token => _token;
  String get username => _username;
  String get password => _password;
  bool get isLoggedIn => _isLoggedIn && (_token.isNotEmpty || (_username.isNotEmpty && _password.isNotEmpty));
  String get userDisplayName => _userDisplayName.isNotEmpty ? _userDisplayName : (_username.isNotEmpty ? _username : 'Usuario');
  int get userId => _userId;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  static AppConfig? _instance;
  static AppConfig get instance => _instance!;

  static Future<AppConfig> init() async {
    final config = AppConfig();
    await config._load();
    _instance = config;
    return config;
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();

    final savedUrl = _prefs.getString(keyBaseUrl);
    // Si no hay URL guardada o tenía la IP local anterior, actualizar a la URL desplegada en la nube:
    if (savedUrl == null || 
        savedUrl.contains('10.0.2.2') || 
        savedUrl.contains('192.168.100.50') || 
        savedUrl.contains('localhost')) {
      _baseUrl = defaultBackendUrl;
      await _prefs.setString(keyBaseUrl, _baseUrl);
    } else {
      _baseUrl = savedUrl;
    }

    final authTypeIndex = _prefs.getInt(keyAuthType) ?? AuthType.basic.index;
    _authType = AuthType.values[authTypeIndex.clamp(0, AuthType.values.length - 1)];
    _token = _prefs.getString(keyToken) ?? '';
    _username = _prefs.getString(keyUsername) ?? '';
    _password = _prefs.getString(keyPassword) ?? '';
    _isLoggedIn = _prefs.getBool(keyIsLoggedIn) ?? false;
    _userDisplayName = _prefs.getString(keyUserDisplayName) ?? '';
    _userId = _prefs.getInt(keyUserId) ?? 0;

    final savedTheme = _prefs.getString(keyThemeMode);
    if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
  }

  Future<void> updateConfig({
    required String newBaseUrl,
    required AuthType newAuthType,
    String? newToken,
    String? newUsername,
    String? newPassword,
  }) async {
    // Clean trailing slash
    var sanitizedUrl = newBaseUrl.trim();
    if (sanitizedUrl.endsWith('/')) {
      sanitizedUrl = sanitizedUrl.substring(0, sanitizedUrl.length - 1);
    }
    if (!sanitizedUrl.endsWith('/~api')) {
      if (sanitizedUrl.endsWith('~api')) {
        // already has ~api
      } else {
        sanitizedUrl = '$sanitizedUrl/~api';
      }
    }

    _baseUrl = sanitizedUrl;
    _authType = newAuthType;
    _token = newToken?.trim() ?? '';
    _username = newUsername?.trim() ?? '';
    _password = newPassword ?? '';

    await _prefs.setString(keyBaseUrl, _baseUrl);
    await _prefs.setInt(keyAuthType, _authType.index);
    await _prefs.setString(keyToken, _token);
    await _prefs.setString(keyUsername, _username);
    await _prefs.setString(keyPassword, _password);

    notifyListeners();
  }

  Future<void> saveUserSession({
    required String username,
    required String password,
    String? displayName,
    int? userId,
  }) async {
    _username = username.trim();
    _password = password;
    _token = '';
    _authType = AuthType.basic;
    _isLoggedIn = true;
    _userDisplayName = displayName ?? _username;
    _userId = userId ?? 0;

    await _prefs.setString(keyUsername, _username);
    await _prefs.setString(keyPassword, _password);
    await _prefs.setString(keyToken, '');
    await _prefs.setInt(keyAuthType, _authType.index);
    await _prefs.setBool(keyIsLoggedIn, true);
    await _prefs.setString(keyUserDisplayName, _userDisplayName);
    await _prefs.setInt(keyUserId, _userId);

    notifyListeners();
  }

  Future<void> saveTokenSession({
    required String token,
    String? displayName,
    int? userId,
  }) async {
    _token = token.trim();
    _username = '';
    _password = '';
    _authType = AuthType.bearer;
    _isLoggedIn = true;
    _userDisplayName = displayName ?? 'Usuario';
    _userId = userId ?? 0;

    await _prefs.setString(keyToken, _token);
    await _prefs.setString(keyUsername, '');
    await _prefs.setString(keyPassword, '');
    await _prefs.setInt(keyAuthType, _authType.index);
    await _prefs.setBool(keyIsLoggedIn, true);
    await _prefs.setString(keyUserDisplayName, _userDisplayName);
    await _prefs.setInt(keyUserId, _userId);

    notifyListeners();
  }

  Future<void> logout() async {
    _token = '';
    _username = '';
    _password = '';
    _authType = AuthType.basic;
    _isLoggedIn = false;
    _userDisplayName = '';
    _userId = 0;

    await _prefs.setString(keyToken, '');
    await _prefs.setString(keyUsername, '');
    await _prefs.setString(keyPassword, '');
    await _prefs.setInt(keyAuthType, _authType.index);
    await _prefs.setBool(keyIsLoggedIn, false);
    await _prefs.setString(keyUserDisplayName, '');
    await _prefs.setInt(keyUserId, 0);

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(keyThemeMode, mode.name);
    notifyListeners();
  }

  Future<void> toggleTheme([BuildContext? context]) async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      final isDark = context != null
          ? (Theme.of(context).brightness == Brightness.dark)
          : false;
      await setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
    }
  }

  Future<void> resetToDefaults() async {
    await logout();
    await updateConfig(
      newBaseUrl: defaultBackendUrl,
      newAuthType: AuthType.basic,
      newToken: '',
      newUsername: '',
      newPassword: '',
    );
  }
}
