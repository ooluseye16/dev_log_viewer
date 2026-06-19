import 'dart:io';
import 'package:dev_log_viewer/log_viewer.dart';

/// Starts the Dev Log Viewer server.
///
/// Usage:
///   dart run tools/log_viewer/bin/log_viewer.dart          # auto-picks a free port starting from 8181
///   dart run tools/log_viewer/bin/log_viewer.dart 9000     # start on a specific port
///
/// After global activation (dart pub global activate --source path tools/log_viewer):
///   dev_log_viewer
///   dev_log_viewer 9000
/// Reads the `name:` field from pubspec.yaml in the current directory.
String? _readProjectName() {
  try {
    final content = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(content);
    return match?.group(1)?.trim();
  } catch (_) {
    return null;
  }
}

void main(List<String> args) async {
  int port = int.tryParse(args.firstOrNull ?? '') ?? 8181;
  final project = _readProjectName();
  const maxTries = 10;

  DevLogServer? server;

  for (int i = 0; i < maxTries; i++) {
    try {
      server = DevLogServer(port: port, project: project);
      await server.start();
      break; // success
    } on SocketException catch (e) {
      final code = e.osError?.errorCode;
      // EADDRINUSE: 48 on macOS/BSD, 98 on Linux
      if (code == 48 || code == 98) {
        if (i < maxTries - 1) {
          stdout.writeln('  Port $port in use — trying ${port + 1}…');
          port++;
        } else {
          stderr.writeln('  Could not find a free port after $maxTries attempts.');
          exit(1);
        }
      } else {
        rethrow;
      }
    }
  }

  final label = project != null ? '$project' : 'Dev Log Viewer';
  stdout.writeln('');
  stdout.writeln('  $label  →  http://localhost:$port');
  if (port != 8181) {
    stdout.writeln('');
    stdout.writeln('  Non-default port. If your app uses auto-discovery (no port arg)');
    stdout.writeln('  it will find this server automatically. Or pass the port explicitly:');
    stdout.writeln('    LogForwarder.init(port: $port)');
  }
  stdout.writeln('');
  stdout.writeln('  Open the URL in your browser, then start your Flutter app.');
  stdout.writeln('  Press Ctrl+C to stop.');
  stdout.writeln('');

  ProcessSignal.sigint.watch().listen((_) async {
    await server?.stop();
    exit(0);
  });
}
