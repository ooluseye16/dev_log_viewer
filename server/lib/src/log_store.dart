import 'models.dart';

const _kMaxEntries = 500;

class LogStore {
  final List<LogEntry> _entries = [];

  List<LogEntry> get entries => List.unmodifiable(_entries);

  final _logListeners = <void Function(LogEntry)>[];
  final _clearListeners = <void Function()>[];

  void add(LogEntry entry) {
    _entries.add(entry);
    if (_entries.length > _kMaxEntries) {
      _entries.removeRange(0, _entries.length - _kMaxEntries);
    }
    for (final l in List.from(_logListeners)) {
      l(entry);
    }
  }

  void clear() {
    _entries.clear();
    for (final l in List.from(_clearListeners)) {
      l();
    }
  }

  void onLog(void Function(LogEntry entry) listener) =>
      _logListeners.add(listener);

  void onClear(void Function() listener) => _clearListeners.add(listener);
}
