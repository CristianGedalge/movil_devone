class ServerStatus {
  final bool isOnline;
  final bool isReady;
  final String version;
  final String url;
  final Duration? pingDuration;
  final String? errorMessage;

  const ServerStatus({
    required this.isOnline,
    required this.isReady,
    required this.version,
    required this.url,
    this.pingDuration,
    this.errorMessage,
  });

  factory ServerStatus.offline(String url, String message) {
    return ServerStatus(
      isOnline: false,
      isReady: false,
      version: 'Desconocida',
      url: url,
      errorMessage: message,
    );
  }

  factory ServerStatus.online({
    required String version,
    required bool isReady,
    required String url,
    Duration? pingDuration,
  }) {
    return ServerStatus(
      isOnline: true,
      isReady: isReady,
      version: version,
      url: url,
      pingDuration: pingDuration,
    );
  }
}
