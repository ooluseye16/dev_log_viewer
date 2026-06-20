# dev_log_client — example app

A minimal Flutter app that demonstrates all three `dev_log_client` integration
options. Tap any tile to fire a log entry and watch it appear in the viewer.

## Running

```bash
# 1. Start the viewer server (once, in a separate terminal):
dart pub global activate dev_log_viewer
dev_log_viewer

# 2. Run the example app:
flutter run -d macos          # or -d chrome / -d <simulator-id>
```

Open the URL printed by the server, then tap buttons in the app.

## What's demonstrated

| Section | API used |
|---------|----------|
| Option A | `LogForwarder.send()` — raw sends with tag, level, and body |
| Option B | `DevLogInterceptor` on a Dio instance — automatic API logging |
| Option C | `AppLog` shortcuts — `auth`, `nav`, `store`, `log`, `error` |
