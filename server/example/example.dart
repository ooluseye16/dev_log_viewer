import 'dart:io';

import 'package:dev_log_viewer/dev_log_viewer.dart';

/// Starts a Dev Log Viewer server on port 8181 and keeps it running.
///
/// In practice you start the server via the CLI:
///   dart pub global activate dev_log_viewer
///   dev_log_viewer
///
/// This example shows how to embed the server programmatically, which is
/// useful if you want to integrate it into your own tooling.
void main() async {
  const port = 8181;
  final server = DevLogServer(port: port, project: 'example');

  await server.start();
  print('Dev Log Viewer running → http://localhost:$port');
  print('Press Ctrl+C to stop.');

  // Keep the process alive. The server handles all incoming requests.
  await ProcessSignal.sigint.watch().first;
  await server.stop();
}
