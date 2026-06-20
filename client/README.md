# dev_log_client

Client library for [dev_log_viewer](https://pub.dev/packages/dev_log_viewer).
Forwards structured log entries from a Flutter/Dart app to the viewer server
running on `localhost`. All logging is a no-op in release builds.

---

## Installation

```yaml
# pubspec.yaml — add under dependencies (or dev_dependencies)
dev_log_client: ^0.1.1
```

Or use the one-command setup wizard from the server package:

```bash
dart pub global activate dev_log_viewer
dev_log_setup   # run from your project root
```

---

## Setup

Call `LogForwarder.init()` once, early in `main()`:

```dart
import 'package:dev_log_client/dev_log_client.dart';

void main() {
  LogForwarder.init();   // auto-discovers the viewer on ports 8181–8185
  runApp(MyApp());
}
```

---

## Three integration options

### Option A — Raw `LogForwarder` (any project)

```dart
LogForwarder.send(tag: 'AUTH', message: 'User signed in');
LogForwarder.send(
  tag: 'ERR',
  message: 'Upload failed',
  level: 'error',
  error: e.toString(),
);
```

### Option B — `DevLogInterceptor` (Dio projects, zero-config API logging)

```dart
dio.interceptors.add(DevLogInterceptor());
```

Every request, response body, status code, and round-trip duration streams to
the viewer automatically.

### Option C — `AppLog` (named tag shortcuts)

```dart
AppLog.auth('User signed in: $uid');
AppLog.nav('Pushed /checkout');
AppLog.store('Cart updated');
AppLog.error('PAY', 'Charge failed', error: e, stack: s);
AppLog.log('CUSTOM', 'anything');   // custom tag
```

Options B and C can be combined — add `DevLogInterceptor` for automatic API
traffic and use `AppLog` for manual events.

---

## Multiple projects simultaneously

The client auto-probes ports 8181–8185 and connects to whichever responds
first — so two Flutter apps can run at the same time without any config.

For explicit control:

```dart
LogForwarder.init(port: 8182);
```

---

## Platform support

Uses `dart:io` (`HttpClient`) — works on **Android, iOS, macOS, Linux, and
Windows**. Not supported on Flutter Web.

---

## Example

A runnable Flutter app demonstrating all three integration options is in
[`example/`](example/lib/main.dart).

---

## Release safety

All client code is guarded by:

```dart
const bool _kDebugMode = !bool.fromEnvironment('dart.vm.product');
```

No connections are made and no logs are sent in release builds.
