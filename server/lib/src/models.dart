class LogEntry {
  LogEntry({
    required this.id,
    required this.timestamp,
    required this.tag,
    required this.level,
    required this.message,
    this.body,
    this.error,
    this.stackTrace,
  });

  final String id;
  final DateTime timestamp;
  final String tag;

  /// One of: info, warning, error
  final String level;
  final String message;

  /// Structured request/response data. Sent as a proper JSON object so the
  /// body is never double-encoded inside the message string.
  final Map<String, dynamic>? body;

  final String? error;
  final String? stackTrace;

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'] as String? ?? nextId(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      tag: json['tag'] as String? ?? 'UNKNOWN',
      level: json['level'] as String? ?? 'info',
      message: json['message'] as String? ?? '',
      body: json['body'] != null
          ? (json['body'] as Map).cast<String, dynamic>()
          : null,
      error: json['error'] as String?,
      stackTrace: json['stackTrace'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'tag': tag,
        'level': level,
        'message': message,
        if (body != null) 'body': body,
        if (error != null) 'error': error,
        if (stackTrace != null) 'stackTrace': stackTrace,
      };

  static int _counter = 0;
  static String nextId() =>
      '${DateTime.now().millisecondsSinceEpoch}-${_counter++}';
}
