import 'dart:convert';
import '../../domain/entities/cashier_connection_mode.dart';
import 'cashier_authority_store.dart';
import 'cashier_bootstrap_validator.dart';
import 'cashier_command_codec.dart';

class CashierBootstrapStore {
  final CashierAuthorityStore authorityStore;
  const CashierBootstrapStore(this.authorityStore);

  /// Fail before contacting the server when local financial work is outstanding.
  Future<String> prepare() async {
    final state = await authorityStore.journal.read();
    _assertDrained(state);
    return CashierCommandCodec.canonical(state);
  }

  Future<Map<String, dynamic>> install(
    Map<String, dynamic> response, {
    required String deviceId,
    required CashierConnectionMode mode,
    required String expectedState,
  }) {
    final copy = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(response)) as Map,
    );
    final journal = authorityStore.journal;
    return journal.mutate((state) {
      _assertDrained(state);
      if (CashierCommandCodec.canonical(state) != expectedState) {
        throw StateError('offline_cashier.bootstrap_changed');
      }
      CashierBootstrapValidator.validate(
        copy,
        journal.actorId,
        journal.loungeId,
      );
      authorityStore.installInState(
        state,
        Map<String, dynamic>.from(copy['authority'] as Map),
        deviceId: deviceId,
        mode: mode,
        allowReleasedReclaim: true,
      );
      for (final key in ['rooms', 'products', 'bookings', 'shift']) {
        state[key] = copy[key];
      }
      state['bootstrap'] = {
        'protocol_version': 2,
        'coverage': copy['coverage'],
        'server_time_ms': (copy['authority'] as Map)['server_time_ms'],
      };
      return copy;
    });
  }

  void _assertDrained(Map state) {
    final release = state['writer_release'];
    if (release is Map && release['status'] != 'released') {
      throw StateError('offline_cashier.release_pending');
    }
    if ((state['outbox'] as List).isNotEmpty ||
        (state['sync_conflicts'] as Map? ?? const {}).isNotEmpty ||
        state['authority_review_required'] == true) {
      throw StateError('offline_cashier.bootstrap_pending');
    }
  }
}
