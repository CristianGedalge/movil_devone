import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../models/server_status.dart';
import '../models/project_model.dart';
import '../models/issue_model.dart';
import '../models/pull_request_model.dart';
import '../models/user_model.dart';

class OneDevService {
  final ApiClient _client;

  OneDevService([ApiClient? client]) : _client = client ?? ApiClient();

  /// Comprueba si el servidor OneDev está levantado, listo y responde
  Future<ServerStatus> checkServerStatus() async {
    final currentUrl = AppConfig.instance.baseUrl;
    final stopwatch = Stopwatch()..start();

    try {
      final versionResponse = await _client.get('/server/version');
      final version = versionResponse?.toString() ?? 'Activo';

      bool isReady = true;
      try {
        final readyResponse = await _client.get('/server/ready');
        if (readyResponse is bool) {
          isReady = readyResponse;
        } else if (readyResponse is String) {
          isReady = readyResponse.toLowerCase() == 'true';
        }
      } catch (_) {
        // Fallback: si version respondió, el servidor está arriba
      }

      stopwatch.stop();
      return ServerStatus.online(
        version: version,
        isReady: isReady,
        url: currentUrl,
        pingDuration: stopwatch.elapsed,
      );
    } on ApiException catch (e) {
      stopwatch.stop();
      return ServerStatus.offline(currentUrl, e.message);
    } catch (e) {
      stopwatch.stop();
      return ServerStatus.offline(currentUrl, e.toString());
    }
  }

  /// Inicia sesión con usuario y contraseña
  Future<UserModel> loginWithCredentials({
    required String username,
    required String password,
  }) async {
    await AppConfig.instance.saveUserSession(
      username: username,
      password: password,
    );

    try {
      UserModel? user;
      try {
        final userData = await _client.get('/users/me');
        if (userData is Map<String, dynamic>) {
          user = UserModel.fromJson(userData);
        }
      } catch (_) {
        // Fallback de validación con /projects
        await _client.get('/projects', queryParameters: {'count': 1});
      }

      final finalUser = user ?? UserModel(id: 0, name: username, fullName: username);
      await AppConfig.instance.saveUserSession(
        username: username,
        password: password,
        displayName: finalUser.displayName,
        userId: finalUser.id,
      );
      return finalUser;
    } catch (e) {
      await AppConfig.instance.logout();
      if (e is ApiException && e.statusCode == 401) {
        throw ApiException('Usuario o contraseña incorrectos.');
      }
      rethrow;
    }
  }

  /// Inicia sesión con Personal Access Token
  Future<UserModel> loginWithToken(String token) async {
    await AppConfig.instance.saveTokenSession(token: token);

    try {
      UserModel? user;
      try {
        final userData = await _client.get('/users/me');
        if (userData is Map<String, dynamic>) {
          user = UserModel.fromJson(userData);
        }
      } catch (_) {
        await _client.get('/projects', queryParameters: {'count': 1});
      }

      final finalUser = user ?? UserModel(id: 0, name: 'Usuario Token');
      await AppConfig.instance.saveTokenSession(
        token: token,
        displayName: finalUser.displayName,
        userId: finalUser.id,
      );
      return finalUser;
    } catch (e) {
      await AppConfig.instance.logout();
      if (e is ApiException && e.statusCode == 401) {
        throw ApiException('El token de acceso no es válido o ha expirado.');
      }
      rethrow;
    }
  }

  /// Obtiene el usuario autenticado actual (/me)
  Future<UserModel?> getCurrentUser() async {
    try {
      final data = await _client.get('/users/me');
      if (data is Map<String, dynamic>) {
        return UserModel.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Lista de proyectos
  Future<List<ProjectModel>> getProjects({String? query, int offset = 0, int count = 50}) async {
    final params = <String, dynamic>{
      'offset': offset,
      'count': count,
    };
    if (query != null && query.trim().isNotEmpty) {
      params['query'] = '"Name" contains "$query"';
    }

    try {
      final response = await _client.get('/projects', queryParameters: params);
      if (response is List) {
        return response
            .map((item) => ProjectModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException && e.statusCode == 404) {
        return [];
      }
      rethrow;
    }
  }

  /// Detalle de proyecto por ID
  Future<ProjectModel> getProject(int projectId) async {
    final response = await _client.get('/projects/$projectId');
    return ProjectModel.fromJson(response as Map<String, dynamic>);
  }

  /// Obtiene URLs de clonación de un proyecto
  Future<Map<String, String>> getCloneUrls(int projectId) async {
    try {
      final response = await _client.get('/projects/$projectId/clone-url');
      if (response is Map) {
        return {
          'http': response['http']?.toString() ?? '',
          'ssh': response['ssh']?.toString() ?? '',
        };
      }
    } catch (_) {}
    return {'http': '', 'ssh': ''};
  }

  /// Lista de incidencias / issues
  Future<List<IssueModel>> getIssues({String? query, int offset = 0, int count = 50}) async {
    final params = <String, dynamic>{
      'withFields': 'true',
      'offset': offset,
      'count': count,
    };
    if (query != null && query.trim().isNotEmpty) {
      params['query'] = query;
    }

    try {
      final response = await _client.get('/issues', queryParameters: params);
      if (response is List) {
        return response
            .map((item) => IssueModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException && e.statusCode == 404) {
        return [];
      }
      rethrow;
    }
  }

  /// Lista de Pull Requests
  Future<List<PullRequestModel>> getPullRequests({String? query, int offset = 0, int count = 50}) async {
    final params = <String, dynamic>{
      'offset': offset,
      'count': count,
    };
    if (query != null && query.trim().isNotEmpty) {
      params['query'] = query;
    }

    try {
      final response = await _client.get('/pulls', queryParameters: params);
      if (response is List) {
        return response
            .map((item) => PullRequestModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException && e.statusCode == 404) {
        return [];
      }
      rethrow;
    }
  }

  /// Crea una incidencia rápida en un proyecto
  Future<int> createIssue({
    required int projectId,
    required String title,
    String? description,
  }) async {
    final body = {
      'projectId': projectId,
      'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
    };
    final response = await _client.post('/issues', body: body);
    if (response is num) {
      return response.toInt();
    }
    return 0;
  }
}
