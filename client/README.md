# dev_log_client

Client library for [dev_log_viewer](https://pub.dev/packages/dev_log_viewer).
Forwards structured log entries from a Flutter/Dart app to the viewer server
running on `localhost`. All logging is a no-op in release builds.

---

## Installation

```yaml
# pubspec.yaml — add under dependencies (or dev_dependencies)
dev_log_client: ^0.2.0
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
  LogForwarder.init(project: 'my_app');   // auto-discovers the viewer on ports 8181–8185
  runApp(MyApp());
}
```

**Pass `project` on iOS/Android.** Discovery prefers a server reporting the
same project name when more than one is running, but the app is sandboxed on
mobile — there's no `pubspec.yaml` on disk to auto-detect it from the way
there is on desktop/CLI targets. Without `project`, discovery still works
(it falls back to picking the lowest port that responds), but it can't tell
your project's server apart from someone else's or a stale one — pass it
explicitly to be sure.

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
the viewer automatically — unredacted, since this only ever travels to
`localhost` while you're actively debugging. The viewer masks fields like
`password`, `pin`, `token`, and `authorization` by default (click to reveal),
so it's safe to glance at or screen-share without exposing credentials, but
the Copy button on any entry always copies the real value — handy for pasting
a failing request straight to a backend developer.

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

Discovery pings every port in 8181–8185 concurrently (via the side-effect-free
`/ping` endpoint) and prefers a server reporting the same `project`, picking
the most recently started one if more than one matches. So two Flutter apps —
or two runs of the same app, old and new — can have viewers open on different
ports at once without the older one winning just because it's on a lower port.

For explicit control (e.g. pinning to a port you know is free):

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
