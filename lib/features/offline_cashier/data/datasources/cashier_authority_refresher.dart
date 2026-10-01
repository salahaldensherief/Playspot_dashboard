import 'dart:async';
import '../../domain/entities/cashier_connection_mode.dart';
import 'cashier_authority_transport.dart';
import 'cashier_authority_store.dart';

class CashierAuthorityRefresher {
  final CashierAuthorityTransport transport;
  final CashierAuthorityStore store;
  Future<void> _tail = Future.value();
  bool _stopped = false;
  CashierAuthorityRefresher({required this.transport, required this.store});
  Future<Map<String, dynamic>> refresh({
    required String deviceId,
    required CashierConnectionMode mode,
  }) {
    final result = Completer<Map<String, dynamic>>();
    _tail = _tail.then((_) async {
      try {
        _checkActive();
        final response = await transport.refresh(
          loungeId: store.journal.loungeId,
          deviceId: deviceId,
          mode: mode,
        );
        _checkActive();
        result.complete(
          await store.install(response, deviceId: deviceId, mode: mode),
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
