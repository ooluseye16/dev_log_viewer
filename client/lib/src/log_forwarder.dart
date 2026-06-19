import 'dart:convert';
import 'dart:io';

// Equivalent to Flutter's kDebugMode but works in pure Dart too.
const bool _kDebugMode = !bool.fromEnvironment('dart.vm.product');

/// Forwards log entries to the Dev Log Viewer server running on localhost.
///
/// Active only in debug builds. Silently no-ops when the server is not running.
///
/// ## Setup
///
/// Call [init] once early in your app's startup:
///
/// ```dart
/// // Auto-discovers the server on ports 8181–8185:
/// LogForwarder.init();
///
/// // Or with an explicit port (useful when two projects run simultaneously):
/// LogForwarder.init(port: 8182);
/// ```
///
/// Then send entries anywhere:
///
/// ```dart
/// LogForwarder.send(tag: 'AUTH', message: 'User signed in');
/// LogForwarder.send(tag: 'ERR', message: 'Upload failed', level: 'error', error: e.toString());
/// ```
class LogForwarder {
  LogForwarder._();

  static Uri? _endpoint;
  static Uri? _sessionEndpoint;

  static final _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 5);

  /// Connects to the Dev Log Viewer server.
  ///
  /// When [port] is omitted, probes ports 8181–8185 and uses the first one
  /// that responds — so multiple projects can run simultaneously on different
  /// ports without any config changes.
  static void init({int? port}) {
    if (!_kDebugMode) return;
    // ignore: discarded_futures
    _discoverAndConnect(port);
  }

  static Future<void> _discoverAndConnect(int? fixedPort) async {
    if (fixedPort != null) {
      _endpoint = Uri.parse('http://localhost:$fixedPort/log');
      _sessionEndpoint = Uri.parse('http://localhost:$fixedPort/session');
      await _postSession();
      return;
    }

    // Auto-probe: POST /session to each candidate port; first success wins.
    // The POST doubles as the session-start handshake.
    for (int p = 8181; p <= 8185; p++) {
      try {
        final sessionUri = Uri.parse('http://localhost:$p/session');
        final req = await _client
            .postUrl(sessionUri)
            .timeout(const Duration(milliseconds: 500));
        req.headers.contentType = ContentType.json;
        req.write('{}');
        final res = await req.close().timeout(const Duration(milliseconds: 500));
        await res.drain<void>();
        _endpoint = Uri.parse('http://localhost:$p/log');
        _sessionEndpoint = sessionUri;
        return;
      } catch (_) {}
    }
  }

  static void send({
    required String tag,
    required String message,
    String level = 'info',
    Map<String, dynamic>? body,
    String? error,
    String? stackTrace,
  }) {
    if (_endpoint == null) return;
    // ignore: discarded_futures
    _post(
      tag: tag,
      message: message,
      level: level,
      body: body,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static Future<void> _postSession() async {
    if (_sessionEndpoint == null) return;
    try {
      final req = await _client
          .postUrl(_sessionEndpoint!)
          .timeout(const Duration(seconds: 5));
      req.headers.contentType = ContentType.json;
      req.write('{}');
      final res = await req.close().timeout(const Duration(seconds: 5));
      await res.drain<void>();
    } catch (_) {}
  }

  static Future<void> _post({
    required String tag,
    required String message,
    required String level,
    Map<String, dynamic>? body,
    String? error,
    String? stackTrace,
  }) async {
    try {
      final req = await _client
          .postUrl(_endpoint!)
          .timeout(const Duration(seconds: 5));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'tag': tag,
        'message': message,
        'level': level,
        'timestamp': DateTime.now().toIso8601String(),
        if (body != null) 'body': body,
        if (error != null) 'error': error,
        if (stackTrace != null) 'stackTrace': stackTrace,
      }));
      final res = await req.close().timeout(const Duration(seconds: 5));
      await res.drain<void>();
    } catch (_) {}
  }
}
