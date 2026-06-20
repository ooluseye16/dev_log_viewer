import 'models.dart';

const _kMaxEntries = 500;

/// In-memory store for [LogEntry] objects, capped at 500 entries.
///
/// Notifies registered listeners whenever an entry is added or all entries
/// are cleared. Used internally by [DevLogServer].
class LogStore {
  final List<LogEntry> _entries = [];

  /// All stored entries, oldest first. Capped at 500.
  List<LogEntry> get entries => List.unmodifiable(_entries);

  final _logListeners = <void Function(LogEntry)>[];
  final _clearListeners = <void Function()>[];

  /// Appends [entry] and notifies [onLog] listeners.
  void add(LogEntry entry) {
    _entries.add(entry);
    if (_entries.length > _kMaxEntries) {
      _entries.removeRange(0, _entries.length - _kMaxEntries);
    }
    for (final l in List.from(_logListeners)) {
      l(entry);
    }
  }

  /// Removes all entries and notifies [onClear] listeners.
  void clear() {
    _entries.clear();
    for (final l in List.from(_clearListeners)) {
      l();
    }
  }

  /// Registers a [listener] called after each [add].
  void onLog(void Function(LogEntry entry) listener) =>
      _logListeners.add(listener);

  /// Registers a [listener] called after each [clear].
  void onClear(void Function() listener) => _clearListeners.add(listener);
}
