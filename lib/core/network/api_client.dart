import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;

  ApiException(this.message, {this.statusCode, this.isNetworkError = false});

  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _client = http.Client();

  Map<String, String> _buildHeaders() {
    final config = AppConfig.instance;
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (config.authType == AuthType.bearer && config.token.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${config.token}';
    } else if (config.authType == AuthType.basic && config.username.isNotEmpty) {
      final raw = '${config.username}:${config.password}';
      final encoded = base64Encode(utf8.encode(raw));
      headers['Authorization'] = 'Basic $encoded';
    }

    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final baseUrl = AppConfig.instance.baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$baseUrl$cleanPath';

    if (queryParameters != null && queryParameters.isNotEmpty) {
      final stringParams = queryParameters.map((key, value) => MapEntry(key, value.toString()));
      return Uri.parse(fullUrl).replace(queryParameters: stringParams);
    }
    return Uri.parse(fullUrl);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final uri = _buildUri(path, queryParameters);
    try {
      final response = await _client
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 12));

      return _handleResponse(response, uri);
    } on SocketException {
      throw ApiException(
        'No se pudo conectar con el servidor OneDev en:\n${AppConfig.instance.baseUrl}\n\n'
        '• Verifica que el servidor esté levantado (./dev.sh run).\n'
        '• Si usas Emulador Android, la IP debe ser: 10.0.2.2:6610\n'
        '• Si usas un celular físico, usa la IP de tu PC (ej. 192.168.x.x).\n'
        '• Puedes cambiar la IP en la pestaña Ajustes.',
        isNetworkError: true,
      );
    } on TimeoutException {
      throw ApiException(
        'Tiempo de espera agotado al conectar con el servidor OneDev. Verifica la conexión de red.',
        isNetworkError: true,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error inesperado de comunicación: $e', isNetworkError: true);
    }
  }

  Future<dynamic> post(String path, {dynamic body}) async {
    final uri = _buildUri(path);
    try {
      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response, uri);
    } on SocketException {
      throw ApiException(
        'No se pudo conectar con el servidor OneDev.',
        isNetworkError: true,
      );
    } on TimeoutException {
      throw ApiException(
        'Tiempo de espera agotado al enviar datos al servidor.',
        isNetworkError: true,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error al procesar solicitud: $e');
    }
  }

  dynamic _handleResponse(http.Response response, Uri uri) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        // Return raw body if not JSON (e.g. plain text version string)
        return response.body;
      }
    }

    if (response.statusCode == 401) {
      throw ApiException(
        'Acceso no autorizado (401). Si tu OneDev requiere autenticación, ingresa tu Token o Usuario/Contraseña en Ajustes.',
        statusCode: 401,
      );
    }

    if (response.statusCode == 403) {
      throw ApiException(
        'Acceso denegado (403). No tienes permisos para acceder a este recurso.',
        statusCode: 403,
      );
    }

    if (response.statusCode == 404) {
      throw ApiException('Recurso no encontrado (404) en $uri', statusCode: 404);
    }

    throw ApiException(
      'Error del servidor (${response.statusCode}): ${response.body.isNotEmpty ? response.body : response.reasonPhrase}',
      statusCode: response.statusCode,
    );
  }
}
