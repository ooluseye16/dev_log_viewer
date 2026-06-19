/// Client library for Dev Log Viewer.
///
/// Three drop-in options — pick one or combine them:
///
/// ---
///
/// ## Option A — Raw [LogForwarder] (minimal, any project)
///
/// ```dart
/// // main():
/// LogForwarder.init();
///
/// // Anywhere:
/// LogForwarder.send(tag: 'AUTH', message: 'Signed in');
/// LogForwarder.send(tag: 'ERR', message: 'Failed', level: 'error', error: e.toString());
/// ```
///
/// ---
///
/// ## Option B — [DevLogInterceptor] (Dio projects, zero-config API logging)
///
/// ```dart
/// // main():
/// LogForwarder.init();
///
/// // Dio setup:
/// dio.interceptors.add(DevLogInterceptor());
/// ```
///
/// Every request, response, and error is automatically streamed to the viewer
/// with full body, status, and duration — no other changes needed.
///
/// ---
///
/// ## Option C — [AppLog] (named tag shortcuts + custom tags)
///
/// ```dart
/// // main():
/// LogForwarder.init();
///
/// // Anywhere:
/// AppLog.auth('User signed in: $uid');
/// AppLog.nav('Pushed /checkout');
/// AppLog.error('PAY', 'Charge failed', error: e, stack: s);
/// AppLog.log('CUSTOM_TAG', 'anything');
/// ```
///
/// ---
///
/// Options B and C can be combined: add [DevLogInterceptor] for automatic
/// API traffic and use [AppLog] for manual events.
library;

export 'src/log_forwarder.dart';
export 'src/dev_log_interceptor.dart';
export 'src/app_log.dart';
