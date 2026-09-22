import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../core/theme/app_theme.dart';
import '../models/chat_message_model.dart';
import '../models/project_model.dart';
import '../services/chat_service.dart';
import '../services/onedev_service.dart';

class ChatView extends StatefulWidget {
  final OneDevService service;

  const ChatView({super.key, required this.service});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  late final ChatService _chatService;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  String _textBeforeSpeech = '';

  List<ProjectModel> _projects = [];
  ProjectModel? _selectedProject;
  bool _loadingProjects = false;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(widget.service);
    _chatService.addListener(_onChatUpdated);
    _loadProjects();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (errorNotification) {
          if (mounted) {
            setState(() => _isListening = false);
          }
        },
      );
      if (mounted) {
        setState(() => _speechAvailable = available);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _speechAvailable = false);
      }
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    if (!_speechAvailable) {
      await _initSpeech();
      if (!_speechAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El micrófono no está disponible o no se otorgaron permisos.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }

    _textBeforeSpeech = _textController.text;
    setState(() => _isListening = true);

    try {
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
        ),
        onResult: (result) {
          if (mounted) {
            setState(() {
              final words = result.recognizedWords;
              if (_textBeforeSpeech.isEmpty) {
                _textController.text = words;
              } else {
                _textController.text = '$_textBeforeSpeech $words'.trim();
              }
              _textController.selection = TextSelection.fromPosition(
                TextPosition(offset: _textController.text.length),
              );
            });
          }
        },
      );
    } catch (_) {
      if (mounted) setState(() => _isListening = false);
    }
  }

  void _onChatUpdated() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  Future<void> _loadProjects() async {
    setState(() => _loadingProjects = true);
    try {
      final list = await widget.service.getProjects(count: 20);
      if (mounted) {
        setState(() {
          _projects = list;
          if (list.isNotEmpty && _selectedProject == null) {
            _selectedProject = list.first;
          }
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingProjects = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _chatService.removeListener(_onChatUpdated);
    _chatService.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend([String? presetText]) {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    }
    final text = presetText ?? _textController.text;
    if (text.trim().isEmpty || _chatService.isLoading) return;

    if (presetText == null) {
      _textController.clear();
    }
    _chatService.sendMessage(text, activeProject: _selectedProject);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildChatHeader(),
          _buildProjectSelectorBar(),
          Expanded(child: _buildMessagesList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    final isLlm = _chatService.providerType == AiProviderType.customLlm;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                child: const Icon(Icons.smart_toy, color: AppTheme.primaryColor, size: 20),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppTheme.statusSuccess,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.cardColor, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PopupMenuButton<String>(
              tooltip: 'Cambiar modelo de IA',
              onSelected: (value) {
                if (value == 'scmdev') {
                  _chatService.selectScmDevAssistant();
                } else {
                  _chatService.selectModel(value);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  enabled: false,
                  child: Text(
                    'MODELOS EN SCMDEV',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                  ),
                ),
                ...ChatService.availableModels.map((model) {
                  final isSelected = isLlm && (_chatService.llmModel == model ||
                      (model == 'Ollama' && (_chatService.llmModel.toLowerCase().contains('llama') || _chatService.llmModel.toLowerCase().contains('ollama'))) ||
                      (model == 'Qwen' && _chatService.llmModel.toLowerCase().contains('qwen')));
                  final subtitle = model == 'Ollama'
                      ? 'llama3.2:latest (Meta)'
                      : 'qwen2.5-coder:3b (Alibaba)';
                  return PopupMenuItem(
                    value: model,
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 16,
                          color: isSelected ? AppTheme.primaryColor : Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              model,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 10,
                                color: context.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'scmdev',
                  child: Row(
                    children: [
                      Icon(
                        !isLlm ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 16,
                        color: !isLlm ? AppTheme.primaryColor : Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'SCMDev Asistente',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            'Proyectos y Pull Requests',
                            style: TextStyle(fontSize: 10, color: context.textSecondaryColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          isLlm
                              ? (_chatService.llmModel.toLowerCase().contains('qwen') ? 'Qwen' : 'Ollama')
                              : 'SCMDev Copilot',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 18, color: context.textSecondaryColor),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.statusSuccess.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'En línea',
                          style: TextStyle(
                            color: AppTheme.statusSuccess,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Toca para cambiar modelo',
                    style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Limpiar conversación',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('¿Limpiar conversación?'),
                  content: const Text('Se borrará el historial actual de mensajes en este chat.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusError),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _chatService.clearChat();
                      },
                      child: const Text('Limpiar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProjectSelectorBar() {
    if (_loadingProjects && _projects.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: context.cardColorHigher,
      child: Row(
        children: [
          Icon(Icons.folder_open, size: 16, color: context.textSecondaryColor),
          const SizedBox(width: 8),
          Text(
            'Contexto:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('General', style: TextStyle(fontSize: 11)),
                    selected: _selectedProject == null,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedProject = null);
                    },
                  ),
                  const SizedBox(width: 6),
                  ..._projects.map((proj) {
                    final isSelected = _selectedProject?.id == proj.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        avatar: Icon(
                          Icons.source,
                          size: 14,
                          color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
                        ),
                        label: Text(
                          proj.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedProject = selected ? proj : null;
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    final messages = _chatService.messages;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: messages.length + (_chatService.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && _chatService.isLoading) {
          return _buildLoadingBubble();
        }

        final msg = messages[index];
        return _buildMessageItem(msg);
      },
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    final isUser = message.isUser;
    final timeStr = DateFormat('HH:mm').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: message.isError
                  ? AppTheme.statusError.withValues(alpha: 0.15)
                  : AppTheme.primaryColor.withValues(alpha: 0.15),
              child: Icon(
                message.isError ? Icons.error_outline : Icons.smart_toy,
                size: 18,
                color: message.isError ? AppTheme.statusError : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppTheme.primaryColor
                        : (message.isError
                            ? const Color(0xFFFEF2F2)
                            : context.cardColor),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                    border: Border.all(
                      color: isUser
                          ? Colors.transparent
                          : (message.isError ? const Color(0xFFFCA5A5) : context.borderColor),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRichMessageText(message.text, isUser, message.isError),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ),
                if (!isUser && message.suggestedActions != null && message.suggestedActions!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: message.suggestedActions!.map((sug) {
                      return ActionChip(
                        avatar: const Icon(Icons.arrow_forward, size: 12),
                        label: Text(sug, style: const TextStyle(fontSize: 11)),
                        onPressed: () => _handleSend(sug),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildRichMessageText(String text, bool isUser, bool isError) {
    if (isUser) {
      return SelectableText(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.4,
        ),
      );
    }

    final textColor = isError ? AppTheme.statusError : context.textPrimaryColor;

    // Detect markdown code blocks: ```bash ... ```
    if (text.contains('```')) {
      final parts = text.split('```');
      final widgets = <Widget>[];

      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];
        if (i % 2 == 1) {
          // Code block
          final lines = part.split('\n');
          final lang = lines.isNotEmpty && !lines[0].contains(' ') ? lines[0] : '';
          final code = lang.isNotEmpty ? lines.sublist(1).join('\n') : part;

          widgets.add(
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang.isNotEmpty ? lang.toUpperCase() : 'CODE',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: code.trim()));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Código copiado al portapapeles'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: const Row(
                          children: [
                            Icon(Icons.copy, size: 14, color: Color(0xFF94A3B8)),
                            SizedBox(width: 4),
                            Text('Copiar', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    code.trim(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      color: Color(0xFFE2E8F0),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          if (part.trim().isNotEmpty) {
            widgets.add(
              SelectableText(
                part.trim(),
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            );
          }
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      );
    }

    return SelectableText(
      text,
      style: TextStyle(
        color: textColor,
        fontSize: 14,
        height: 1.4,
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
            child: const Icon(Icons.smart_toy, size: 18, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                ),
                SizedBox(width: 10),
                Text(
                  'El asistente está respondiendo...',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(top: BorderSide(color: context.borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isListening)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Escuchando... habla para dictar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(left: 14, right: 6),
                  decoration: BoxDecoration(
                    color: context.cardColorHigher,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isListening ? Colors.redAccent : context.borderColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: _isListening
                                ? 'Escuchando tu voz...'
                                : 'Pregunta algo sobre tus proyectos o git...',
                            hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onSubmitted: (_) => _handleSend(),
                        ),
                      ),
                      IconButton(
                        tooltip: _isListening ? 'Detener dictado' : 'Dictar por voz',
                        icon: Icon(
                          _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                          color: _isListening ? Colors.redAccent : context.textSecondaryColor,
                          size: 22,
                        ),
                        onPressed: _toggleListening,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _chatService.isLoading ? null : () => _handleSend(),
                icon: _chatService.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
