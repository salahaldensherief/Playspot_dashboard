import 'dart:async';
import '../../domain/entities/cashier_connection_mode.dart';
import 'cashier_bootstrap_store.dart';
import 'cashier_bootstrap_transport.dart';

class CashierBootstrapRefresher {
  final CashierBootstrapTransport transport;
  final CashierBootstrapStore store;
  Future<void> _tail = Future.value();
  bool _stopped = false;
  CashierBootstrapRefresher({required this.transport, required this.store});

  Future<Map<String, dynamic>> refresh({
    required String deviceId,
    required CashierConnectionMode mode,
  }) {
    final result = Completer<Map<String, dynamic>>();
    _tail = _tail.then((_) async {
      try {
        _checkActive();
        final expected = await store.prepare();
        _checkActive();
        final response = await transport.load(
          loungeId: store.authorityStore.journal.loungeId,
          deviceId: deviceId,
          mode: mode,
        );
        _checkActive();
        result.complete(
          await store.install(
            response,
            deviceId: deviceId,
            mode: mode,
            expectedState: expected,
          ),
        );
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    });
    return result.future;
  }

  void stop() => _stopped = true;
  void _checkActive() {
    if (_stopped) throw StateError('offline_cashier.journal_closed');
  }
}
