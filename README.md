# Dev Log Viewer

A real-time local log viewer for Flutter/Dart development.

Receives structured log entries from your running app and serves a searchable,
filterable web UI on `localhost`. Built for debugging API traffic, errors, and
app events without staring at a wall of console output.

| Package | pub.dev | Purpose |
|---------|---------|---------|
| [`dev_log_viewer`](server/) | [![pub](https://img.shields.io/pub/v/dev_log_viewer.svg)](https://pub.dev/packages/dev_log_viewer) | CLI server + web UI |
| [`dev_log_client`](client/) | [![pub](https://img.shields.io/pub/v/dev_log_client.svg)](https://pub.dev/packages/dev_log_client) | Flutter/Dart client library |

---

## Quick start

### 1. Start the server

```bash
dart pub global activate dev_log_viewer
dev_log_viewer
```

Auto-picks a free port starting from **8181**. Open the URL it prints in your browser.

### 2. Add the client to your Flutter project

```yaml
# pubspec.yaml
dependencies:
  dev_log_client: ^0.1.0
```

Or let the setup wizard do both steps:

```bash
dev_log_setup   # run from your Flutter project root
```

### 3. Initialise in main()

```dart
import 'package:dev_log_client/dev_log_client.dart';

void main() {
  LogForwarder.init();
  runApp(MyApp());
}
```

### 4. Choose your integration

**Option A — Raw sends** (any project, no extra deps):
```dart
LogForwarder.send(tag: 'AUTH', message: 'User signed in');
LogForwarder.send(tag: 'ERR',  message: 'Upload failed', level: 'error', error: e.toString());
```

**Option B — Dio interceptor** (zero-config API logging):
```dart
dio.interceptors.add(DevLogInterceptor());
```
Every request, response body, status code, and round-trip duration streams
to the viewer automatically — no other changes needed.

**Option C — AppLog** (named tag shortcuts):
```dart
AppLog.auth('Signed in: $uid');
AppLog.nav('Pushed /checkout');
AppLog.error('PAY', 'Charge failed', error: e, stack: s);
AppLog.log('CART', 'Item added: $itemId');   // custom tag
```

Options B and C can be combined.

---

## Features

- **Real-time** via Server-Sent Events — no polling
- **JSON pretty-print** with syntax highlighting for request/response bodies
- **Deep search** across JSON keys AND values at any nesting depth
- **Tag + level filters** — API, AUTH, NAV, STORE, ERR, or any custom tag
- **Request duration** — shown on every response row (e.g. `· 42ms`)
- **Hot-restart separators** — "Hot restarted at 14:23:01" divider in the log list
- **Pause / resume** — freeze the live stream while you read; buffered entries flush on resume
- **Collapse / expand all** — one click to tidy up expanded entries
- **500-entry cap** — server and browser both trim oldest entries automatically
- **Survives browser reload** — history served via `GET /logs`, live events via SSE
- **Multi-project** — auto-discovers the right server on ports 8181–8185
- **Zero production impact** — all logging is suppressed in release builds

---

## Multiple projects simultaneously

The server auto-increments if the default port is taken:
```
Port 8181 in use — trying 8182…
my_app  →  http://localhost:8182
```

The client auto-probes 8181–8185 and connects to whichever responds first.
For explicit control: `LogForwarder.init(port: 8182)`.

---

## Release safety

All client code is guarded by:
```dart
const bool _kDebugMode = !bool.fromEnvironment('dart.vm.product');
```
No logs are sent, no connections are made in release/production builds.

---

## Repository

[github.com/ooluseye16/dev_log_viewer](https://github.com/ooluseye16/dev_log_viewer)
