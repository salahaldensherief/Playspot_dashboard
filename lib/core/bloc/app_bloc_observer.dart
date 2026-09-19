import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Information wrapper for an active Bloc/Cubit instance in memory.
class _ActiveBlocInfo {
  final String name;
  final DateTime createdAt;

  _ActiveBlocInfo({required this.name, required this.createdAt});
}

/// A comprehensive global [BlocObserver] that logs all BLoC and Cubit lifecycle
/// events, state transitions, and unhandled errors across the entire app.
///
/// Holds in-memory session diagnostics and statistics accessible via
/// [AppBlocObserver.printSummary()]. All logging and data collection are strictly
/// guarded by [kDebugMode] for zero overhead in release/production builds.
class AppBlocObserver extends BlocObserver {
  // In-memory session statistics (guarded by kDebugMode)
  static final Map<int, _ActiveBlocInfo> _activeBlocs = {};
  static final Map<String, int> _createdCounts = {};
  static final Map<String, int> _closedCounts = {};
  static final Map<String, int> _changeCounts = {};
  static final Map<String, int> _errorCounts = {};

  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) return;
    developer.log(message, name: 'BLOC', error: error, stackTrace: stackTrace);
    debugPrint('[BLOC] $message');
  }

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
    _log('🟢 [CREATE] $name (#$hash) at $timeStr');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    if (!kDebugMode) return;

    _log('📥 [EVENT] ${bloc.runtimeType} -> $event');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (!kDebugMode) return;

    final name = bloc.runtimeType.toString();
    _changeCounts[name] = (_changeCounts[name] ?? 0) + 1;

    final currentType = change.currentState.runtimeType.toString();
    final nextType = change.nextState.runtimeType.toString();

    _log('🔄 [CHANGE] $name: $currentType ➔ $nextType');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    if (!kDebugMode) return;

    _log(
      '🛤️ [TRANSITION] ${bloc.runtimeType}:\n'
      '   Event: ${transition.event.runtimeType}\n'
      '   From:  ${_shorten(transition.currentState)}\n'
      '   To:    ${_shorten(transition.nextState)}',
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    if (!kDebugMode) return;

    final name = bloc.runtimeType.toString();
    _errorCounts[name] = (_errorCounts[name] ?? 0) + 1;

    _log(
      '🔴 [ERROR] $name:\n   Error: $error',
      error: error,
      stackTrace: stackTrace,
    );
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
    _log('🔴 [CLOSE] $name (#$hash) at $timeStr');
  }

  String _shorten(Object? state) {
    final str = state.toString();
    if (str.length > 200) {
      return '${str.substring(0, 200)}... (truncated)';
    }
    return str;
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

    // 2. Lifetime Instance Counts (Created vs Closed)
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
