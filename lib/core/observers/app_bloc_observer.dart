import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Information wrapper for an active Bloc/Cubit instance in memory.
class _ActiveBlocInfo {
  final String name;
  final DateTime createdAt;

  _ActiveBlocInfo({required this.name, required this.createdAt});
}

/// Global BLoC/Cubit Observer for logging lifecycle events and collecting
/// session diagnostics. All logging and data collection are strictly guarded
/// by [kDebugMode] to ensure zero overhead in production (Release builds).
class AppBlocObserver extends BlocObserver {
  // In-memory session statistics (guarded by kDebugMode)
  static final Map<int, _ActiveBlocInfo> _activeBlocs = {};
  static final Map<String, int> _createdCounts = {};
  static final Map<String, int> _closedCounts = {};
  static final Map<String, int> _changeCounts = {};
  static final Map<String, int> _errorCounts = {};

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    if (!kDebugMode) return;

    final now = DateTime.now();
    final name = bloc.runtimeType.toString();
    final hash = identityHashCode(bloc);

    _activeBlocs[hash] = _ActiveBlocInfo(name: name, createdAt: now);
    _createdCounts[name] = (_createdCounts[name] ?? 0) + 1;

    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}";
    debugPrint('🟢 [BLOC][CREATE] $name (#$hash) at $timeStr');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (!kDebugMode) return;

    final name = bloc.runtimeType.toString();
    _changeCounts[name] = (_changeCounts[name] ?? 0) + 1;

    final currentType = change.currentState.runtimeType.toString();
    final nextType = change.nextState.runtimeType.toString();

    debugPrint('🔄 [BLOC][CHANGE] $name: $currentType ➔ $nextType');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    if (!kDebugMode) return;

    final name = bloc.runtimeType.toString();
    final eventName = transition.event.runtimeType.toString();

    debugPrint('⚡ [BLOC][TRANSITION] $name: Event $eventName');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    if (!kDebugMode) return;

    final name = bloc.runtimeType.toString();
    _errorCounts[name] = (_errorCounts[name] ?? 0) + 1;

    debugPrint('🔴 [BLOC][ERROR] $name: $error\n$stackTrace');
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    if (!kDebugMode) return;

    final now = DateTime.now();
    final name = bloc.runtimeType.toString();
    final hash = identityHashCode(bloc);

    _activeBlocs.remove(hash);
    _closedCounts[name] = (_closedCounts[name] ?? 0) + 1;

    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}";
    debugPrint('🔴 [BLOC][CLOSE] $name (#$hash) at $timeStr');
  }

  /// Prints a comprehensive diagnostic summary of all Cubits/Blocs in the current session.
  static void printSummary() {
    if (!kDebugMode) return;

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('===============================================================');
    buffer.writeln('📊 [BLOC OBSERVER DIAGNOSTICS SUMMARY]');
    buffer.writeln('===============================================================');

    // 1. Currently Active (Alive) Cubits / Blocs
    buffer.writeln('🟢 Active (Alive) Cubits/Blocs (${_activeBlocs.length}):');
    if (_activeBlocs.isEmpty) {
      buffer.writeln('   (No active Cubits currently in memory)');
    } else {
      final Map<String, int> activeTypeCounts = {};
      for (final info in _activeBlocs.values) {
        activeTypeCounts[info.name] = (activeTypeCounts[info.name] ?? 0) + 1;
      }
      for (final entry in activeTypeCounts.entries) {
        buffer.writeln('   • ${entry.key}: ${entry.value} active instance(s)');
      }
    }

    // 2. Lifetime Lifecycle Counts (Created vs Closed)
    buffer.writeln('\n📈 Lifetime Instance Counts (Created / Closed):');
    final allNames = {..._createdCounts.keys, ..._closedCounts.keys};
    for (final name in allNames) {
      final created = _createdCounts[name] ?? 0;
      final closed = _closedCounts[name] ?? 0;
      final diff = created - closed;
      final leakWarning = diff > 0 ? ' ⚠️ ($diff unclosed instance(s))' : '';
      buffer.writeln('   • $name: $created created, $closed closed$leakWarning');
    }

    // 3. State Changes Count (Rebuild Activity)
    buffer.writeln('\n🔄 State Change Activity (onChange count per Cubit):');
    if (_changeCounts.isEmpty) {
      buffer.writeln('   (No state changes recorded yet)');
    } else {
      final sortedChanges = _changeCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sortedChanges) {
        buffer.writeln('   • ${entry.key}: ${entry.value} state change(s)');
      }
    }

    // 4. Errors Count
    buffer.writeln('\n🔴 Error Counts per Cubit:');
    if (_errorCounts.isEmpty) {
      buffer.writeln('   (No errors recorded 🎉)');
    } else {
      for (final entry in _errorCounts.entries) {
        buffer.writeln('   • ${entry.key}: ${entry.value} error(s)');
      }
    }

    buffer.writeln('===============================================================');
    debugPrint(buffer.toString());
  }
}
