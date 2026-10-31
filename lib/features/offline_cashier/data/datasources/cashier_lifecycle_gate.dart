import 'dart:async';

/// Serializes authority/bootstrap/release before their request snapshots are
/// taken. A release cannot freeze an old permit while renewal is in flight.
class CashierLifecycleGate {
  Future<void> _tail = Future.value();

  Future<T> run<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        result.complete(await operation());
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    });
    return result.future;
  }
}
