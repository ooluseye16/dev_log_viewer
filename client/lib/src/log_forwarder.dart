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
  /// When [port] is omitted, pings ports 8181–8185 concurrently and prefers
  /// a server that reports this same project, picking the most recently
  /// started one among those — so a stale instance from days ago no longer
  /// wins just because it happens to sit on a lower port.
  ///
  /// Pass [project] explicitly on iOS/Android — the running app is sandboxed
  /// there, so there's no pubspec.yaml on disk to auto-detect from the way
  /// there is on desktop/CLI targets:
  /// ```dart
  /// LogForwarder.init(project: 'my_app');
  /// ```
  static void init({int? port, String? project}) {
    if (!_kDebugMode) return;
    // ignore: discarded_futures
    _discoverAndConnect(port, project);
  }

  /// Reads the `name:` field from pubspec.yaml in the current working
  /// directory. Only ever resolves on desktop/CLI targets, where the Dart
  /// VM's working directory is a real path on the host filesystem — on
  /// iOS/Android the app runs in a sandbox with no such file, so this is
  /// purely a convenience fallback, not the primary mechanism.
  static String? _readProjectName() {
    try {
      final content = File('pubspec.yaml').readAsStringSync();
      final match =
          RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(content);
      return match?.group(1)?.trim();
    } catch (_) {
      return null;
    }
  }

  static Future<void> _discoverAndConnect(
      int? fixedPort, String? explicitProject) async {
    if (fixedPort != null) {
      _endpoint = Uri.parse('http://localhost:$fixedPort/log');
      _sessionEndpoint = Uri.parse('http://localhost:$fixedPort/session');
      await _postSession();
      return;
    }

    final myProject = explicitProject ?? _readProjectName();
    final candidates = [for (int p = 8181; p <= 8185; p++) p];

    // Ping every candidate concurrently — /ping has no side effects, unlike
    // /session (which appends a log line). POSTing /session to each port in
    // turn would both litter every live server's log with a stray "App
    // started" entry AND lock onto whichever port answers first, which is
    // exactly how a days-old zombie on 8181 wins over the instance you just
    // opened to watch.
    final pings = await Future.wait(candidates.map(_ping));

    final responders = <int, Map<String, dynamic>>{
      for (var i = 0; i < candidates.length; i++)
        if (pings[i] != null) candidates[i]: pings[i]!,
    };
    if (responders.isEmpty) return;

    final sameProject = myProject == null
        ? <MapEntry<int, Map<String, dynamic>>>[]
        : responders.entries
            .where((e) => e.value['project'] == myProject)
            .toList();

    int chosenPort;
    if (sameProject.isNotEmpty) {
      // Prefer the most recently started server for this exact project —
      // that's the one the developer just opened to watch right now.
      sameProject.sort((a, b) {
        final aStarted =
            DateTime.tryParse(a.value['startedAt']?.toString() ?? '');
        final bStarted =
            DateTime.tryParse(b.value['startedAt']?.toString() ?? '');
        // A server with no startedAt is a pre-fix build — always rank it
        // below one that reports a timestamp, never tie with it.
        if (aStarted == null && bStarted == null) return 0;
        if (aStarted == null) return 1;
        if (bStarted == null) return -1;
        return bStarted.compareTo(aStarted);
      });
      chosenPort = sameProject.first.key;
    } else {
      // No same-project match (older server build without the field, or
      // genuinely a different project) — keep the previous behaviour.
      chosenPort = responders.keys.reduce((a, b) => a < b ? a : b);
    }

    _endpoint = Uri.parse('http://localhost:$chosenPort/log');
    _sessionEndpoint = Uri.parse('http://localhost:$chosenPort/session');
    await _postSession();
  }

  /// GETs /ping on [port]; returns the decoded JSON body, or null if that
  /// port isn't a Dev Log Viewer instance (closed, refused, bad payload).
  static Future<Map<String, dynamic>?> _ping(int port) async {
    try {
      final uri = Uri.parse('http://localhost:$port/ping');
      final req =
          await _client.getUrl(uri).timeout(const Duration(milliseconds: 500));
      final res = await req.close().timeout(const Duration(milliseconds: 500));
      final body = await res.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
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
      final req =
          await _client.postUrl(_endpoint!).timeout(const Duration(seconds: 5));
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
