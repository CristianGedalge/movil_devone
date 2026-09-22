import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message_model.dart';
import '../models/project_model.dart';
import '../services/onedev_service.dart';

enum AiProviderType {
  scmdevAssistant,
  customLlm,
}

class ChatService extends ChangeNotifier {
  static const String keyProvider = 'scmdev_ai_provider';
  static const String keyLlmBaseUrl = 'scmdev_llm_base_url';
  static const String keyLlmApiKey = 'scmdev_llm_api_key';
  static const String keyLlmModel = 'scmdev_llm_model';

  static const List<String> availableModels = [
    'Ollama',
    'Qwen',
  ];

  final OneDevService _oneDevService;
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  AiProviderType _providerType = AiProviderType.scmdevAssistant;
  late String _llmBaseUrl = defaultCloudUrl;
  late String _llmApiKey = defaultCloudApiKey;
  String _llmModel = 'Ollama';

  ChatService(this._oneDevService) {
    _loadSettings();
    _initWelcomeMessage();
  }

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  AiProviderType get providerType => _providerType;
  String get llmBaseUrl => _llmBaseUrl;
  String get llmApiKey => _llmApiKey;
  String get llmModel => _llmModel;

  // Credenciales cargadas desde .env
  static String get defaultCloudUrl {
    final envUrl = dotenv.isInitialized ? dotenv.env['AI_PROXY_URL'] : null;
    return (envUrl != null && envUrl.isNotEmpty)
        ? envUrl
        : 'http://54.160.217.3:8443/v1';
  }

  static String get defaultCloudApiKey {
    final envKey = dotenv.isInitialized ? dotenv.env['AI_PROXY_API_KEY'] : null;
    return (envKey != null && envKey.isNotEmpty)
        ? envKey
        : '5ac58f4bd44cb7697a1d1aa481ca4bf6';
  }

  Future<void> selectModel(String modelName) async {
    _llmModel = modelName;
    _providerType = AiProviderType.customLlm;
    if (_llmBaseUrl.contains('10.0.2.2') ||
        _llmBaseUrl.contains('192.168.') ||
        _llmBaseUrl.contains('localhost') ||
        _llmBaseUrl.isEmpty) {
      _llmBaseUrl = defaultCloudUrl;
      _llmApiKey = defaultCloudApiKey;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyProvider, 'customLlm');
      await prefs.setString(keyLlmModel, _llmModel);
      await prefs.setString(keyLlmBaseUrl, _llmBaseUrl);
      await prefs.setString(keyLlmApiKey, _llmApiKey);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> selectScmDevAssistant() async {
    _providerType = AiProviderType.scmdevAssistant;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyProvider, 'scmdev');
    } catch (_) {}
    notifyListeners();
  }

  void _initWelcomeMessage() {
    _messages.add(
      ChatMessage.assistant(
        '¡Hola! Soy tu **Asistente IA de SCMDev** 🤖.\n\n'
        'Puedo ayudarte a consultar información sobre tus proyectos, Pull Requests, comandos Git y actividades del repositorio.\n\n'
        '¿Qué te gustaría consultar hoy?',
        suggestions: [
          '📊 Resumen de mis proyectos',
          '🔀 Estado de Pull Requests',
          '📌 ¿Cómo clono un repositorio?',
          '💡 Comandos Git recomendados',
        ],
      ),
    );
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prov = prefs.getString(keyProvider);
      if (prov != null) {
        _providerType = prov == 'customLlm'
            ? AiProviderType.customLlm
            : AiProviderType.scmdevAssistant;
      }
      final savedUrl = prefs.getString(keyLlmBaseUrl);
      if (savedUrl != null &&
          (savedUrl.contains('10.0.2.2') ||
           savedUrl.contains('192.168.') ||
           savedUrl.contains('localhost'))) {
        await prefs.remove(keyLlmBaseUrl);
        await prefs.remove(keyLlmApiKey);
        _llmBaseUrl = defaultCloudUrl;
        _llmApiKey = defaultCloudApiKey;
      } else if (savedUrl != null && savedUrl.isNotEmpty) {
        _llmBaseUrl = savedUrl;
      }
      final savedKey = prefs.getString(keyLlmApiKey);
      if (savedKey != null && savedKey.isNotEmpty) {
        _llmApiKey = savedKey;
      }
      final savedModel = prefs.getString(keyLlmModel);
      if (savedModel != null && savedModel.isNotEmpty) {
        if (savedModel.contains('Phi')) {
          _llmModel = 'Ollama';
        } else if (savedModel.toLowerCase().contains('qwen')) {
          _llmModel = 'Qwen';
        } else if (savedModel.toLowerCase().contains('llama') || savedModel.toLowerCase().contains('ollama')) {
          _llmModel = 'Ollama';
        } else {
          _llmModel = savedModel;
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> updateSettings({
    required AiProviderType providerType,
    required String llmBaseUrl,
    required String llmApiKey,
    required String llmModel,
  }) async {
    _providerType = providerType;
    _llmBaseUrl = llmBaseUrl.trim();
    _llmApiKey = llmApiKey.trim();
    _llmModel = llmModel.trim().isEmpty ? 'local-model' : llmModel.trim();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyProvider, _providerType == AiProviderType.customLlm ? 'customLlm' : 'scmdev');
      await prefs.setString(keyLlmBaseUrl, _llmBaseUrl);
      await prefs.setString(keyLlmApiKey, _llmApiKey);
      await prefs.setString(keyLlmModel, _llmModel);
    } catch (_) {}

    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _initWelcomeMessage();
    notifyListeners();
  }

  Future<void> sendMessage(String text, {ProjectModel? activeProject}) async {
    final query = text.trim();
    if (query.isEmpty || _isLoading) return;

    final userMsg = ChatMessage.user(query);
    _messages.add(userMsg);
    _isLoading = true;
    notifyListeners();

    try {
      ChatMessage responseMsg;

      if (_providerType == AiProviderType.customLlm) {
        responseMsg = await _sendToCustomLlm(query, activeProject);
      } else {
        responseMsg = await _processScmDevAssistantQuery(query, activeProject);
      }

      _messages.add(responseMsg);
    } catch (e) {
      _messages.add(ChatMessage.error('Ocurrió un error inesperado al procesar tu solicitud: $e'));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ChatMessage> _sendToCustomLlm(String query, ProjectModel? activeProject) async {
    var urlStr = _llmBaseUrl;
    if (!urlStr.endsWith('/')) urlStr += '/';
    final completionsUri = Uri.parse('${urlStr}chat/completions');

    final projectDescription = (activeProject?.description != null && activeProject!.description!.trim().isNotEmpty)
        ? 'Descripción del proyecto: "${activeProject.description!.trim()}". '
        : '';

    final projectContext = activeProject != null
        ? 'El usuario está trabajando en el proyecto "${activeProject.name}" (Ruta: ${activeProject.displayPath}). $projectDescription'
        : 'SCMDev es una plataforma de control de versiones y colaboración Git. ';

    var modelToUse = 'llama3.2:latest';
    final modelLower = _llmModel.trim().toLowerCase();
    if (modelLower.contains('qwen')) {
      modelToUse = 'qwen2.5-coder:3b';
    } else {
      modelToUse = 'llama3.2:latest';
    }

    debugPrint('>>> [ChatService] Enviando a: $completionsUri');
    debugPrint('>>> [ChatService] Modelo: $modelToUse, API Key: ${_llmApiKey.isNotEmpty ? "${_llmApiKey.substring(0, 5)}..." : "VACIA"}');

    String modelIdentity;
    if (modelToUse.contains('qwen')) {
      modelIdentity = 'Eres Qwen (qwen2.5-coder), un modelo de inteligencia artificial desarrollado por Alibaba Cloud. ';
    } else {
      modelIdentity = 'Eres LLaMA (llama3.2), un modelo de inteligencia artificial servido mediante Ollama y desarrollado por Meta. ';
    }

    final systemPrompt =
        '$modelIdentity'
        'Actúas como el asistente inteligente oficial de la plataforma SCMDev. '
        '$projectContext'
        'Responde de manera precisa, profesional, clara y concisa en español (máximo 2 párrafos breves a menos que te pidan código detallado). '
        'Nunca digas que eres Claude ni que fuiste creado por Anthropic. '
        'Usa formato Markdown con viñetas cuando sea apropiado.';

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_llmApiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_llmApiKey';
      headers['X-API-Key'] = _llmApiKey;
    }

    final payload = {
      'model': modelToUse,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': query},
      ],
      'temperature': 0.7,
      'max_tokens': 250,
      'stream': false,
    };

    try {
      final response = await http
          .post(
            completionsUri,
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 400));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final first = choices.first as Map<String, dynamic>;
          final msgObj = first['message'] as Map<String, dynamic>?;
          final content = msgObj?['content']?.toString() ?? 'Sin respuesta del modelo.';
          return ChatMessage.assistant(content);
        }
        return ChatMessage.assistant('El modelo respondió con un formato inesperado.');
      } else {
        return ChatMessage.error(
          'Error HTTP ${response.statusCode} al conectar con el servidor LLM.\n'
          'Respuesta: ${response.body.length > 150 ? "${response.body.substring(0, 150)}..." : response.body}',
        );
      }
    } on TimeoutException {
      return ChatMessage.error(
        'El servidor de IA tardó en responder más de 400 segundos.\n'
        'El servidor en la nube está con alta carga o generando una respuesta extensa. Por favor reintenta con una consulta más puntual.',
      );
    } catch (e) {
      return ChatMessage.error(
        'No se pudo conectar a "$completionsUri": $e\n'
        'Verifica tu conexión a internet o intenta nuevamente en unos momentos.',
      );
    }
  }

  Future<ChatMessage> _processScmDevAssistantQuery(String query, ProjectModel? activeProject) async {
    final lower = query.toLowerCase();

    // 1. Consulta de proyectos
    if (lower.contains('proyecto') || lower.contains('repositorio') || lower.contains('repos')) {
      try {
        final projects = await _oneDevService.getProjects(count: 10);
        if (projects.isEmpty) {
          return ChatMessage.assistant(
            'Actualmente no tienes proyectos asignados o visibles en SCMDev.\n'
            'Puedes crear o unirte a un proyecto desde la interfaz web.',
          );
        }

        final buffer = StringBuffer();
        buffer.writeln('📁 **Tus proyectos en SCMDev (${projects.length}):**\n');
        for (var i = 0; i < projects.length; i++) {
          final p = projects[i];
          buffer.writeln('${i + 1}. **${p.name}** (`${p.displayPath}`)');
          if (p.description != null && p.description!.isNotEmpty) {
            buffer.writeln('   *${p.description}*');
          }
        }
        buffer.writeln('\n💡 *Puedes seleccionar cualquiera de ellos para ver detalles o consultar Pull Requests.*');

        return ChatMessage.assistant(
          buffer.toString(),
          suggestions: [
            '🔀 Pull Requests abiertos',
            '📌 ¿Cómo clono ${projects.first.name}?',
          ],
        );
      } catch (e) {
        return ChatMessage.assistant('No pude recuperar la lista de proyectos en este momento: $e');
      }
    }

    // 2. Consulta de Pull Requests
    if (lower.contains('pull request') || lower.contains('pull') || lower.contains('pr')) {
      try {
        final pulls = await _oneDevService.getPullRequests(count: 10);
        if (pulls.isEmpty) {
          return ChatMessage.assistant(
            '🎉 ¡Todo al día! No se encontraron Pull Requests pendientes en SCMDev.',
            suggestions: ['📊 Resumen de mis proyectos', '💡 Comandos Git recomendados'],
          );
        }

        final openPulls = pulls.where((p) => p.isOpen).toList();
        final buffer = StringBuffer();
        buffer.writeln('🔀 **Pull Requests en SCMDev:**\n');
        buffer.writeln('• Abiertos: **${openPulls.length}**');
        buffer.writeln('• Total cargados: **${pulls.length}**\n');

        for (final pr in pulls.take(5)) {
          final statusBadge = pr.isOpen ? '🟢 [Abierto]' : '🟣 [Cerrado]';
          buffer.writeln('$statusBadge **#${pr.number} ${pr.title}**');
          buffer.writeln('   De `${pr.sourceBranch}` a `${pr.targetBranch}`');
          buffer.writeln('   Por: @${pr.submitterName}\n');
        }

        return ChatMessage.assistant(
          buffer.toString(),
          suggestions: ['📊 Ver proyectos', '💡 ¿Cómo revisar un PR?'],
        );
      } catch (e) {
        return ChatMessage.assistant('No se pudieron obtener los Pull Requests: $e');
      }
    }

    // 3. Consulta de cómo clonar
    if (lower.contains('clonar') || lower.contains('clone') || lower.contains('url')) {
      if (activeProject != null) {
        try {
          final urls = await _oneDevService.getCloneUrls(activeProject.id);
          final httpUrl = urls['http'] ?? '';
          final sshUrl = urls['ssh'] ?? '';

          return ChatMessage.assistant(
            '📋 **Instrucciones de clonación para "${activeProject.name}":**\n\n'
            '**Vía HTTPS:**\n'
            '```bash\n'
            'git clone ${httpUrl.isNotEmpty ? httpUrl : "https://scmdev.erikaguilarchuviru.dev/${activeProject.displayPath}.git"}\n'
            '```\n\n'
            '${sshUrl.isNotEmpty ? "**Vía SSH:**\n```bash\ngit clone $sshUrl\n```\n\n" : ""}'
            '📌 Luego de clonar, accede a la carpeta con `cd ${activeProject.name}` y verifica el estado con `git status`.',
            suggestions: ['💡 Comandos Git recomendados', '🔀 Pull Requests'],
          );
        } catch (_) {}
      }

      return ChatMessage.assistant(
        '💡 Para clonar un repositorio en SCMDev:\n\n'
        '1. Selecciona tu proyecto en la pestaña **Proyectos**.\n'
        '2. En el detalle del proyecto encontrarás los comandos HTTPS y SSH listos para copiar con un solo toque.\n'
        '3. O selecciona un proyecto en la parte superior de este chat.',
        suggestions: ['📊 Resumen de mis proyectos'],
      );
    }

    // 4. Comandos Git recomendados
    if (lower.contains('git') || lower.contains('comando') || lower.contains('rama') || lower.contains('branch')) {
      return ChatMessage.assistant(
        '🛠️ **Comandos Git esenciales en el flujo SCMDev:**\n\n'
        '• **Crear y cambiar a una rama de trabajo:**\n'
        '  ```bash\n'
        '  git checkout -b feature/mi-nueva-funcionalidad\n'
        '  ```\n\n'
        '• **Confirmar cambios realizados:**\n'
        '  ```bash\n'
        '  git add .\n'
        '  git commit -m "feat: descripción clara del cambio"\n'
        '  ```\n\n'
        '• **Subir tu rama al servidor SCMDev:**\n'
        '  ```bash\n'
        '  git push -u origin feature/mi-nueva-funcionalidad\n'
        '  ```\n\n'
        '• **Actualizar tu rama principal:**\n'
        '  ```bash\n'
        '  git checkout master\n'
        '  git pull origin master\n'
        '  ```\n\n'
        'Una vez subida tu rama, puedes abrir un **Pull Request** directamente para revisión.',
        suggestions: ['🔀 Estado de Pull Requests', '📊 Mis proyectos'],
      );
    }

    // 5. Consulta genérica o respuesta informativa
    final activeInfo = activeProject != null
        ? 'Actualmente estás enfocado en **${activeProject.name}**.\n\n'
        : '';

    return ChatMessage.assistant(
      '${activeInfo}Puedo ayudarte con información de tus repositorios SCMDev.\n\n'
      '¿Deseas consultar proyectos, revisar Pull Requests o aprender a clonar un repositorio?\n\n'
      '⚙️ *Tip: Si deseas respuestas de un modelo de lenguaje general como LM Studio u Ollama, pulsa el icono de engranaje en la esquina superior para configurar tu servidor LLM.*',
      suggestions: [
        '📊 Resumen de mis proyectos',
        '🔀 Pull Requests abiertos',
        '💡 Comandos Git recomendados',
        '📌 ¿Cómo clono un repositorio?',
      ],
    );
  }
}
