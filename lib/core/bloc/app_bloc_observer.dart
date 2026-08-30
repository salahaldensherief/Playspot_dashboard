import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    developer.log('🚀 Created: ${bloc.runtimeType}', name: 'BLOC');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    developer.log('📥 Event: ${bloc.runtimeType} -> $event', name: 'BLOC');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    // This will catch both Cubit and Bloc changes
    developer.log(
      '🔄 Change in ${bloc.runtimeType}:\n'
      '   From: ${change.currentState}\n'
      '   To:   ${change.nextState}',
      name: 'BLOC',
    );
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    developer.log(
      '🛤️ Transition in ${bloc.runtimeType}:\n'
      '   Event: ${transition.event}\n'
      '   From:  ${transition.currentState}\n'
      '   To:    ${transition.nextState}',
      name: 'BLOC',
    );
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    developer.log(
      '❌ Error in ${bloc.runtimeType}:\n'
      '   Error: $error',
      name: 'BLOC',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    developer.log('🚪 Closed: ${bloc.runtimeType}', name: 'BLOC');
  }
}
