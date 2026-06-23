# Changelog

## 0.2.0

- **`LogForwarder.init()` now accepts an optional `project` parameter.**
  Auto-detecting the project name by reading `pubspec.yaml` only ever
  worked on desktop/CLI targets — on iOS/Android the app runs sandboxed
  with no such file on disk, so discovery silently fell back to "lowest
  port wins." Pass `project` explicitly on mobile:
  ```dart
  LogForwarder.init(project: 'my_app');
  ```
- Discovery no longer connects to whichever server answers first. It pings
  every candidate port (8181–8185) concurrently via the side-effect-free
  `/ping` endpoint, then prefers a server reporting the same project,
  picking the most recently started one among those. Previously a stale
  server from a previous run (or a different project) on a lower port
  would win the race every time.
- `DevLogInterceptor` request/response/error bodies are sent unredacted —
  this is a localhost-only, debug-only tool, and the point is being able
  to inspect (and copy) real request/response data while debugging. The
  viewer UI masks sensitive fields by default and reveals them on click
  instead.

## 0.1.1

- Documentation only — dartdoc comments added across the public API, no
  behavioural changes.

## 0.1.0

- Initial release.
- `LogForwarder` — raw log sender with auto-discovery across ports 8181–8185.
- `DevLogInterceptor` — zero-config Dio interceptor for automatic API traffic logging.
- `AppLog` — named tag shortcuts (`auth`, `nav`, `store`, `api`, `error`, `log`).
- All output suppressed automatically in release builds via `dart.vm.product`.
