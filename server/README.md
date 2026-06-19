# dev_log_viewer

A real-time local log viewer for Flutter/Dart development. Runs a local HTTP
server that receives structured log entries from your running app and serves
a searchable, filterable web UI on `localhost` via Server-Sent Events.

---

## Installation

Activate globally so `dev_log_viewer` is available from any directory:

```bash
dart pub global activate dev_log_viewer
```

Or run directly from source:

```bash
dart run bin/log_viewer.dart
```

---

## Usage

```bash
dev_log_viewer           # auto-picks a free port starting from 8181
dev_log_viewer 9000      # explicit port
```

Open the URL printed in the terminal, then start your Flutter app.

If port 8181 is taken, the server automatically tries 8182, 8183, and so on —
useful when two projects run simultaneously.

---

## One-command project setup

```bash
dev_log_setup
```

Run from your Flutter/Dart project root. It:
1. Detects your project type (Flutter, Dart, Dio)
2. Adds `dev_log_client` to `pubspec.yaml`
3. Patches `lib/main.dart` with `LogForwarder.init()`
4. Runs `pub get`
5. Prints the one remaining manual step

---

## Features

- **Real-time** via Server-Sent Events — no polling
- **JSON pretty-print** with syntax highlighting for request/response bodies
- **Deep search** across JSON keys AND values at any nesting depth
- **Tag + level filters** — API, AUTH, NAV, STORE, ERR, or any custom tag
- **Request duration** shown on every response row (`· 42ms`)
- **Hot-restart separators** — "Hot restarted at 14:23:01" divider in the log list
- **Pause / resume** — freeze the live stream while you read; buffered entries flush on resume
- **Collapse / expand all** — one click to tidy up expanded entries
- **500-entry cap** — server and browser both trim oldest entries automatically
- **Survives browser reload** — history served via `GET /logs`, live events via SSE
- **Multi-project** — auto-discovers the right server on ports 8181–8185

---

## HTTP API

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/` | Web UI |
| `GET` | `/logs` | All stored entries (JSON) |
| `GET` | `/stream` | SSE live stream |
| `POST` | `/log` | Ingest a log entry |
| `POST` | `/session` | Signal app start / hot restart |
| `DELETE` | `/logs` | Clear all entries |
| `GET` | `/ping` | Health check |

---

## Client library

Use [`dev_log_client`](https://pub.dev/packages/dev_log_client) in your app to
forward logs to this server.
