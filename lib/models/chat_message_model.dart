class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final List<String>? suggestedActions;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.suggestedActions,
  });

  factory ChatMessage.user(String text) {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.assistant(String text, {List<String>? suggestions}) {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
      suggestedActions: suggestions,
    );
  }

  factory ChatMessage.error(String errorText) {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: errorText,
      isUser: false,
      timestamp: DateTime.now(),
      isError: true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'isError': isError,
    'suggestedActions': suggestedActions,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    text: json['text'] as String,
    isUser: json['isUser'] as bool,
    timestamp: DateTime.parse(json['timestamp'] as String),
    isError: json['isError'] as bool? ?? false,
    suggestedActions: (json['suggestedActions'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
  );
}
