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
        'No se pudo conectar con el servidor. Verifica tu conexión de red e intenta nuevamente.',
        isNetworkError: true,
      );
    } on TimeoutException {
      throw ApiException(
        'El servidor tardó demasiado en responder. Por favor intenta de nuevo.',
        isNetworkError: true,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error de conexión con el servicio.', isNetworkError: true);
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
        'No se pudo conectar con el servidor. Revisa tu conexión.',
        isNetworkError: true,
      );
    } on TimeoutException {
      throw ApiException(
        'Tiempo de espera agotado al comunicarse con el servidor.',
        isNetworkError: true,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error al procesar la solicitud.');
    }
  }

  dynamic _handleResponse(http.Response response, Uri uri) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        // Return raw body if not JSON
        return response.body;
      }
    }

    if (response.statusCode == 401) {
      throw ApiException(
        'Credenciales inválidas o sesión expirada. Por favor ingresa tus datos.',
        statusCode: 401,
      );
    }

    if (response.statusCode == 403) {
      throw ApiException(
        'No tienes permisos suficientes para realizar esta acción.',
        statusCode: 403,
      );
    }

    if (response.statusCode == 404) {
      throw ApiException('Elemento o recurso no encontrado.', statusCode: 404);
    }

    throw ApiException(
      'Error en la solicitud (${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }
}
