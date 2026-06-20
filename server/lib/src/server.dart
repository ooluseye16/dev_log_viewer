import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'log_store.dart';
import 'models.dart';
import 'ui.dart';

class DevLogServer {
  DevLogServer({this.port = 8181, this.project});

  final int port;
  final String? project;
  final LogStore _store = LogStore();
  final List<StreamController<List<int>>> _clients = [];

  HttpServer? _server;

  Future<void> start() async {
    final router = Router()
      ..get('/', _ui)
      ..get('/ping', _ping)
      ..get('/logs', _getLogs)
      ..post('/log', _postLog)
      ..post('/session', _postSession)
      ..delete('/logs', _clearLogs);

    final shelfHandler = Pipeline()
        .addMiddleware(_cors())
        .addHandler(router.call);

    // Use raw dart:io so we can set bufferOutput = false on the SSE response.
    // Shelf's addStream never calls flush(), so events would sit in the buffer
    // until the OS decided to send them. Direct dart:io lets us flush per-event.
    _server = await HttpServer.bind('localhost', port);
    _server!.listen((request) {
      if (request.method == 'GET' && request.uri.path == '/stream') {
        _handleSseRaw(request);
      } else {
        io.handleRequest(request, shelfHandler);
      }
    });

    _store.onLog(_broadcast);
    _store.onClear(_broadcastClear);
  }

  Future<void> stop() async => _server?.close(force: true);

  // ── Route handlers ─────────────────────────────────────────────────────────

  Response _ping(Request _) => Response.ok(
        jsonEncode({
          'port': port,
          'status': 'ok',
          if (project != null) 'project': project,
        }),
        headers: {'content-type': 'application/json'},
      );

  Response _ui(Request _) => Response.ok(
        kLogViewerHtml,
        headers: {'content-type': 'text/html; charset=utf-8'},
      );

  Response _getLogs(Request _) => Response.ok(
        jsonEncode(_store.entries.map((e) => e.toJson()).toList()),
        headers: {'content-type': 'application/json'},
      );

  Future<Response> _postLog(Request request) async {
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;
      _store.add(LogEntry.fromJson(json));
      return Response.ok('ok');
    } catch (e) {
      return Response.badRequest(body: 'bad payload: $e');
    }
  }

  Response _postSession(Request _) {
    final isRestart = _store.entries.isNotEmpty;
    _store.add(LogEntry(
      id: LogEntry.nextId(),
      timestamp: DateTime.now(),
      tag: 'SESSION',
      level: 'info',
      message: isRestart ? 'Hot restarted' : 'App started',
    ));
    return Response.ok('ok');
  }

  Response _clearLogs(Request _) {
    _store.clear();
    return Response.ok('cleared');
  }

  // ── SSE — raw dart:io so we control flushing ───────────────────────────────

  void _handleSseRaw(HttpRequest request) async {
    final res = request.response;
    res.headers
      ..set('content-type', 'text/event-stream; charset=utf-8')
      ..set('cache-control', 'no-cache')
      ..set('x-accel-buffering', 'no')
      ..set('access-control-allow-origin', '*');
    // Disable Dart's output buffering — each write goes to the socket immediately.
    res.bufferOutput = false;

    final ctrl = StreamController<List<int>>(sync: true);
    _clients.add(ctrl);

    // When the client disconnects, close ctrl so the await-for loop below exits.
    // ignore: discarded_futures
    res.done.whenComplete(() { if (!ctrl.isClosed) ctrl.close(); });

    final ping = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!ctrl.isClosed) ctrl.add(utf8.encode(': ping\n\n'));
    });

    try {
      await for (final chunk in ctrl.stream) {
        res.add(chunk);
        await res.flush();
      }
    } catch (_) {}

    ping.cancel();
    _clients.remove(ctrl);
    if (!ctrl.isClosed) unawaited(ctrl.close());
    try { await res.close(); } catch (_) {}
  }

  // ── SSE broadcast ──────────────────────────────────────────────────────────

  List<int> _sseData(LogEntry entry) =>
      utf8.encode('data: ${jsonEncode(entry.toJson())}\n\n');

  void _broadcast(LogEntry entry) {
    final data = _sseData(entry);
    for (final c in List.from(_clients)) {
      if (!c.isClosed) {
        try {
          c.add(data);
        } catch (_) {
          _clients.remove(c);
        }
      }
    }
  }

  void _broadcastClear() {
    final data = utf8.encode('event: clear\ndata: {}\n\n');
    for (final c in List.from(_clients)) {
      if (!c.isClosed) {
        try {
          c.add(data);
        } catch (_) {
          _clients.remove(c);
        }
      }
    }
  }

  // ── CORS middleware ────────────────────────────────────────────────────────

  static const _corsHeaders = {
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET, POST, DELETE, OPTIONS',
    'access-control-allow-headers': 'content-type',
  };

  Middleware _cors() => (Handler inner) => (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        final res = await inner(request);
        return res.change(headers: _corsHeaders);
      };
}
