# Dev Log Viewer

A real-time local log viewer for Flutter/Dart development.

Receives structured log entries from your running app and serves a searchable,
filterable web UI on `localhost`. Built for debugging API traffic, errors, and
app events without staring at a wall of console output.

---

## Packages

| Package | Purpose |
|---|---|
| [`server/`](server/) | Shelf HTTP server + SSE stream + web UI |
| [`client/`](client/) | Flutter/Dart client — pick one of three options |

---

## Quick start

### 1. Start the server

```bash
# From anywhere after global activation:
dart pub global activate --source path /path/to/dev_log_viewer/server
dev_log_viewer
```

Or run directly from this repo:
```bash
dart run server/bin/log_viewer.dart
```

Auto-picks a free port starting from **8181**. Open the URL it prints in your browser.

### 2. Add the client to your Flutter project

```yaml
# pubspec.yaml
dependencies:
  dev_log_client:
    path: /path/to/dev_log_viewer/client   # or git URL once published
```

### 3. Choose your integration

**Option A — Raw sends** (works in any project, no extra deps):
```dart
// main.dart
LogForwarder.init();

// Anywhere:
LogForwarder.send(tag: 'AUTH', message: 'User signed in');
LogForwarder.send(tag: 'ERR',  message: 'Upload failed', level: 'error', error: e.toString());
```

**Option B — Dio interceptor** (zero-config API logging):
```dart
// main.dart
LogForwarder.init();

// Dio setup:
dio.interceptors.add(DevLogInterceptor());
```
Every request, response body, status code, and round-trip duration streams
to the viewer automatically — no other changes needed.

**Option C — AppLog** (named tag shortcuts):
```dart
// main.dart
LogForwarder.init();

// Anywhere:
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
- **Multi-project** — auto-discovers the right server on ports 8181–8185; or pass `LogForwarder.init(port: 8182)` to be explicit
- **Zero production impact** — all logging is suppressed in release builds

---

## Multiple projects simultaneously

The server auto-increments if the default port is taken:
```
Port 8181 in use — trying 8182…
numoni  →  http://localhost:8182
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
