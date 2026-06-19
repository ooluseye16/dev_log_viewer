import 'dart:io';

/// One-time setup wizard for adding Dev Log Client to a Flutter/Dart project.
///
/// Run from your project root after globally activating dev_log_viewer:
///
///   dev_log_setup
///
/// It will:
///   1. Detect your project type (Flutter, Dart, Dio, etc.)
///   2. Add dev_log_client to pubspec.yaml
///   3. Patch lib/main.dart with LogForwarder.init()
///   4. Print the one remaining manual step (Dio interceptor line)
void main(List<String> args) async {
  _header();

  // ── 1. Validate project root ────────────────────────────────────────────────
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    _fail('No pubspec.yaml found. Run dev_log_setup from your project root.');
  }

  final pubspec = pubspecFile.readAsStringSync();
  final projectName = _extract(pubspec, 'name') ?? 'your_app';
  final isFlutter = pubspec.contains('sdk: flutter') || pubspec.contains("sdk: 'flutter'");
  final hasDio = RegExp(r'^\s+dio:', multiLine: true).hasMatch(pubspec);
  final alreadyHasClient = pubspec.contains('dev_log_client');

  _line('Project  : $projectName');
  _line('Type     : ${isFlutter ? 'Flutter' : 'Dart'}');
  _line('Dio      : ${hasDio ? 'yes' : 'no'}');
  stdout.writeln('');

  // ── 2. Add dev_log_client dependency ────────────────────────────────────────
  if (alreadyHasClient) {
    _ok('dev_log_client already in pubspec.yaml');
  } else {
    _addClientDependency(pubspecFile, pubspec);
    _ok('Added dev_log_client to pubspec.yaml');
  }

  // ── 3. Patch main.dart ──────────────────────────────────────────────────────
  final mainFile = _findMainDart();

  if (mainFile == null) {
    _warn('Could not find lib/main.dart — add this manually:');
    _codeBlock("import 'package:dev_log_client/dev_log_client.dart';\n\n// In main():\nLogForwarder.init();");
  } else {
    final original = mainFile.readAsStringSync();

    if (original.contains('LogForwarder.init')) {
      _ok('LogForwarder.init() already present in ${mainFile.path}');
    } else {
      final patched = _patchMain(original);
      if (patched != null) {
        mainFile.writeAsStringSync(patched);
        _ok('Patched ${mainFile.path}');
      } else {
        _warn('Could not auto-patch ${mainFile.path} — add this manually:');
        _codeBlock("import 'package:dev_log_client/dev_log_client.dart';\n\n// First line of main():\nLogForwarder.init();");
      }
    }
  }

  // ── 4. Run pub get ──────────────────────────────────────────────────────────
  stdout.writeln('');
  _line('Running dart pub get…');
  final pubGet = await Process.run(
    isFlutter ? 'flutter' : 'dart',
    ['pub', 'get'],
    runInShell: true,
  );
  if (pubGet.exitCode == 0) {
    _ok('Dependencies installed');
  } else {
    _warn('pub get failed — run it manually:');
    _codeBlock(isFlutter ? 'flutter pub get' : 'dart pub get');
  }

  // ── 5. Print remaining steps ─────────────────────────────────────────────────
  stdout.writeln('');
  stdout.writeln('  ┌─ One remaining step ──────────────────────────────────────');
  if (hasDio) {
    stdout.writeln('  │');
    stdout.writeln('  │  Add to your Dio setup:');
    stdout.writeln('  │');
    stdout.writeln('  │    dio.interceptors.add(DevLogInterceptor());');
  } else {
    stdout.writeln('  │');
    stdout.writeln('  │  Log anything with:');
    stdout.writeln('  │');
    stdout.writeln("  │    LogForwarder.send(tag: 'TAG', message: 'your message');");
    stdout.writeln('  │');
    stdout.writeln('  │  Or use AppLog for named shortcuts:');
    stdout.writeln('  │');
    stdout.writeln("  │    AppLog.log('AUTH', 'User signed in');");
    stdout.writeln("  │    AppLog.error('NET', 'Request failed', error: e);");
  }
  stdout.writeln('  │');
  stdout.writeln('  └───────────────────────────────────────────────────────────');
  stdout.writeln('');
  stdout.writeln('  Then start the viewer in a terminal:');
  stdout.writeln('');
  stdout.writeln('    dev_log_viewer');
  stdout.writeln('');
  stdout.writeln('  Open http://localhost:8181 — done.');
  stdout.writeln('');
}

// ── Helpers ───────────────────────────────────────────────────────────────────

void _header() {
  stdout.writeln('');
  stdout.writeln('  ╔══════════════════════════════╗');
  stdout.writeln('  ║   Dev Log Viewer — Setup     ║');
  stdout.writeln('  ╚══════════════════════════════╝');
  stdout.writeln('');
}

void _ok(String msg)   => stdout.writeln('  ✓  $msg');
void _warn(String msg) => stdout.writeln('  ⚠  $msg');
void _line(String msg) => stdout.writeln('  $msg');
void _codeBlock(String code) {
  stdout.writeln('');
  for (final line in code.split('\n')) {
    stdout.writeln('     $line');
  }
  stdout.writeln('');
}
void _fail(String msg) {
  stderr.writeln('\n  ✗  $msg\n');
  exit(1);
}

/// Extracts a top-level scalar field from a pubspec.yaml string.
String? _extract(String yaml, String key) {
  final match = RegExp('^$key:\\s*(.+)\$', multiLine: true).firstMatch(yaml);
  return match?.group(1)?.trim();
}

File? _findMainDart() {
  final candidates = ['lib/main.dart', 'bin/main.dart', 'main.dart'];
  for (final path in candidates) {
    final f = File(path);
    if (f.existsSync()) return f;
  }
  return null;
}

/// Adds dev_log_client under the dependencies section.
void _addClientDependency(File pubspecFile, String content) {
  // Prefer pub.dev style; adjust to git/path if needed before publishing.
  const snippet = '  dev_log_client: ^0.1.0';

  // Find the dependencies: block and insert there.
  final depsMatch = RegExp(r'^dependencies:', multiLine: true).firstMatch(content);
  if (depsMatch != null) {
    final insertAt = content.indexOf('\n', depsMatch.end) + 1;
    final patched = content.substring(0, insertAt) + snippet + '\n' + content.substring(insertAt);
    pubspecFile.writeAsStringSync(patched);
    return;
  }

  // No dependencies block — append one.
  pubspecFile.writeAsStringSync(content.trimRight() + '\n\ndependencies:\n$snippet\n');
}

/// Adds the import and LogForwarder.init() call to main.dart.
/// Returns the patched content, or null if it couldn't be done safely.
String? _patchMain(String content) {
  // Arrow-syntax main (e.g. void main() => runApp(...)) — don't touch it.
  if (RegExp(r'void main\([^)]*\)\s*=>').hasMatch(content)) return null;

  const importLine = "import 'package:dev_log_client/dev_log_client.dart';";
  String result = content;

  // ── Add import after the last existing import line ──────────────────────────
  if (!result.contains('dev_log_client')) {
    final allImports = RegExp(r"^import .+;$", multiLine: true).allMatches(result).toList();
    if (allImports.isNotEmpty) {
      final end = result.indexOf('\n', allImports.last.end) + 1;
      result = result.substring(0, end) + '$importLine\n' + result.substring(end);
    } else {
      result = '$importLine\n\n$result';
    }
  }

  // ── Insert LogForwarder.init() ──────────────────────────────────────────────
  // Best: right after ensureInitialized().
  final ensureIdx = result.indexOf('ensureInitialized()');
  if (ensureIdx != -1) {
    final semi = result.indexOf(';', ensureIdx);
    if (semi != -1) {
      result = '${result.substring(0, semi + 1)}\n  LogForwarder.init();${result.substring(semi + 1)}';
      return result;
    }
  }

  // Fallback: first line inside the main() body.
  final mainMatch = RegExp(r'void main\([^)]*\)\s*(?:async\s*)?\{').firstMatch(result);
  if (mainMatch != null) {
    result = '${result.substring(0, mainMatch.end)}\n  LogForwarder.init();${result.substring(mainMatch.end)}';
    return result;
  }

  return null;
}
