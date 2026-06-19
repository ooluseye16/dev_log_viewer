/// A local development log viewer for Flutter apps.
///
/// Start the server:
/// ```dart
/// final server = DevLogServer(port: 8181);
/// await server.start();
/// print('Viewer at http://localhost:8181');
/// ```
library;

export 'src/models.dart' show LogEntry;
export 'src/log_store.dart' show LogStore;
export 'src/server.dart' show DevLogServer;
