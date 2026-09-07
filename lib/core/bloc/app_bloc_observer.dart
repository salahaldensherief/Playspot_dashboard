import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A global [BlocObserver] that logs all BLoC and Cubit lifecycle events,
/// state transitions, events, and unhandled errors across the entire app.
class AppBlocObserver extends BlocObserver {
  void _log(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: 'BLOC', error: error, stackTrace: stackTrace);
    if (kDebugMode) {
      debugPrint('[BLOC] $message');
      if (error != null) {
        debugPrint('[BLOC_ERROR] $error');
      }
    }
  }

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    _log('🚀 Created: ${bloc.runtimeType}');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    _log('📥 Event: ${bloc.runtimeType} -> $event');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    _log(
      '🔄 Change in ${bloc.runtimeType}:\n'
      '   From: ${_shorten(change.currentState)}\n'
      '   To:   ${_shorten(change.nextState)}',
    );
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    _log(
      '🛤️ Transition in ${bloc.runtimeType}:\n'
      '   Event: ${transition.event}\n'
      '   From:  ${_shorten(transition.currentState)}\n'
      '   To:    ${_shorten(transition.nextState)}',
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    _log(
      '❌ Error in ${bloc.runtimeType}:\n   Error: $error',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    _log('🚪 Closed: ${bloc.runtimeType}');
  }

  String _shorten(Object? state) {
    final str = state.toString();
    if (str.length > 300) {
      return '${str.substring(0, 300)}... (truncated)';
    }
    return str;
  }
}
