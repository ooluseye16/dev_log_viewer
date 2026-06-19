import 'dart:convert';
import 'package:dio/dio.dart';
import 'log_forwarder.dart';

/// Drop-in Dio interceptor that streams all API traffic to Dev Log Viewer.
///
/// Logs every request, response, and error — including method, URL, status
/// code, request/response bodies, and round-trip duration. Zero configuration.
///
/// ## Setup
///
/// ```dart
/// // 1. Start the server (once, in your terminal):
/// //    dev_log_viewer
///
/// // 2. In main():
/// LogForwarder.init();
///
/// // 3. Add to any Dio instance:
/// dio.interceptors.add(DevLogInterceptor());
/// ```
///
/// That's it. Open http://localhost:8181 and watch traffic flow in real time.
///
/// If your Dio instance already has an interceptor that handles auth or
/// retries, you can add [DevLogInterceptor] alongside it — the two are
/// fully independent.
class DevLogInterceptor extends Interceptor {
  /// Key used to store the request start time in [RequestOptions.extra].
  static const _startKey = '_devLogStartMs';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;

    final body = <String, dynamic>{};
    if (options.queryParameters.isNotEmpty) body['query'] = options.queryParameters;
    if (options.data != null) {
      try { body['body'] = jsonDecode(jsonEncode(options.data)); } catch (_) {}
    }

    LogForwarder.send(
      tag: 'API',
      message: '--> ${options.method} ${options.baseUrl}${options.path}',
      body: body.isEmpty ? null : body,
    );

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final durationStr = _duration(response.requestOptions);

    LogForwarder.send(
      tag: 'API',
      message: '<-- ${response.statusCode} '
          '${response.requestOptions.baseUrl}${response.requestOptions.path}'
          '$durationStr',
      body: _safeBody(response.data),
    );

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final durationStr = _duration(err.requestOptions);
    final status = err.response?.statusCode ?? err.type.name;

    LogForwarder.send(
      tag: 'API',
      message: '${err.requestOptions.method} '
          '${err.requestOptions.baseUrl}${err.requestOptions.path} '
          '→ $status$durationStr',
      level: 'error',
      body: _safeBody(err.response?.data),
      error: err.message,
    );

    super.onError(err, handler);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _duration(RequestOptions options) {
    final startMs = options.extra[_startKey] as int?;
    if (startMs == null) return '';
    return ' · ${DateTime.now().millisecondsSinceEpoch - startMs}ms';
  }

  static Map<String, dynamic>? _safeBody(dynamic value) {
    if (value == null) return null;
    try {
      return {'data': jsonDecode(jsonEncode(value))};
    } catch (_) {
      return {'data': value.toString()};
    }
  }
}
