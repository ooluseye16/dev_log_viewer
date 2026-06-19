import 'dart:developer' as dev;
import 'log_forwarder.dart';

const bool _kDebugMode = !bool.fromEnvironment('dart.vm.product');

/// Lightweight tagged logger that forwards entries to Dev Log Viewer.
///
/// Provides named shortcuts for common tags, plus [log] for custom ones.
/// All output is suppressed in release builds automatically.
///
/// ## Built-in tags
///
/// | Method            | Tag        | Colour in viewer |
/// |-------------------|------------|-----------------|
/// | [api]             | `API`      | Blue            |
/// | [auth]            | `AUTH`     | Green           |
/// | [nav]             | `NAV`      | Orange          |
/// | [store]           | `STORE`    | Cyan            |
/// | [error]           | `ERR:<tag>`| Red             |
/// | [log] (any tag)   | custom     | Grey            |
///
/// ## Setup
///
/// ```dart
/// // main():
/// LogForwarder.init();
/// ```
///
/// Then call anywhere:
///
/// ```dart
/// AppLog.auth('User signed in: $uid');
/// AppLog.nav('Pushed /checkout');
/// AppLog.error('PAYMENT', 'Charge failed', error: e, stack: s);
/// AppLog.log('CART', 'Item added: $itemId');  // custom tag
/// ```
///
/// ## Adding your own tags
///
/// Extend or wrap this class to add project-specific shortcuts:
///
/// ```dart
/// extension AppLogX on AppLog {
///   static void pay(String msg) => AppLog.log('PAY', msg);
///   static void notif(String msg) => AppLog.log('NOTIF', msg);
/// }
/// ```
class AppLog {
  AppLog._();

  // ── Named shortcuts ───────────────────────────────────────────────────────

  static void api(String message, {Map<String, dynamic>? body}) =>
      _emit('API', message, body: body);

  static void auth(String message) => _emit('AUTH', message);

  static void nav(String message) => _emit('NAV', message);

  static void store(String message) => _emit('STORE', message);

  /// Log with any custom [tag]. The tag appears as a filter chip in the viewer.
  static void log(String tag, String message) => _emit(tag, message);

  // ── Error ─────────────────────────────────────────────────────────────────

  /// Logs an error. The entry appears in red under the `ERR:<tag>` filter.
  ///
  /// Pass [error] and [stack] to include them as expandable sections in the
  /// viewer. Pass [body] for a structured JSON response body (e.g. API errors).
  static void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stack,
    Map<String, dynamic>? body,
  }) {
    if (!_kDebugMode) return;
    dev.log('[ERR:$tag] $message', name: 'ERR:$tag', error: error, stackTrace: stack);
    LogForwarder.send(
      tag: 'ERR:$tag',
      message: message,
      level: 'error',
      body: body,
      error: error?.toString(),
      stackTrace: stack?.toString(),
    );
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  static void _emit(String tag, String message, {Map<String, dynamic>? body}) {
    if (!_kDebugMode) return;
    dev.log('[$tag] $message', name: tag);
    LogForwarder.send(tag: tag, message: message, body: body);
  }
}
