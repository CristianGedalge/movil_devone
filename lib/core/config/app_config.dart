import 'package:flutter/foundation.dart';
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

  // Preset default URLs
  static const String defaultEmulatorUrl = 'http://10.0.2.2:6610/~api';
  static const String defaultLocalhostUrl = 'http://localhost:6610/~api';

  late SharedPreferences _prefs;

  String _baseUrl = defaultEmulatorUrl;
  AuthType _authType = AuthType.none;
  String _token = '';
  String _username = '';
  String _password = '';

  String get baseUrl => _baseUrl;
  AuthType get authType => _authType;
  String get token => _token;
  String get username => _username;
  String get password => _password;

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

    // Default URL depends on platform:
    final platformDefault = (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        ? defaultEmulatorUrl
        : defaultLocalhostUrl;

    _baseUrl = _prefs.getString(keyBaseUrl) ?? platformDefault;
    final authTypeIndex = _prefs.getInt(keyAuthType) ?? AuthType.none.index;
    _authType = AuthType.values[authTypeIndex.clamp(0, AuthType.values.length - 1)];
    _token = _prefs.getString(keyToken) ?? '';
    _username = _prefs.getString(keyUsername) ?? '';
    _password = _prefs.getString(keyPassword) ?? '';
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

  Future<void> resetToDefaults() async {
    final platformDefault = (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        ? defaultEmulatorUrl
        : defaultLocalhostUrl;

    await updateConfig(
      newBaseUrl: platformDefault,
      newAuthType: AuthType.none,
      newToken: '',
      newUsername: '',
      newPassword: '',
    );
  }
}
