import 'dart:async';
import '../../domain/entities/cashier_connection_mode.dart';
import 'encrypted_cashier_journal.dart';
import 'cashier_authority_refresher.dart';

/// Keeps the online lease alive across route changes. Network failure never
/// silently grants local writing while an uncertain online request may commit.
class CashierWriterHeartbeat {
  final EncryptedCashierJournal journal;
  final CashierAuthorityRefresher refresher;
  Timer? _timer;
  bool _running = false;
  bool _stopped = false;
  CashierWriterHeartbeat(this.journal, this.refresher);
  void start() {
    if (_stopped) return;
    _timer ??= Timer.periodic(
      const Duration(seconds: 20),
      (_) => unawaited(tick()),
    );
  }

  Future<void> tick() async {
    if (_stopped || _running) return;
    _running = true;
    try {
      final state = await journal.read();
      final authority = state['authority'];
      if (state['bootstrap'] is! Map ||
          state['writer_release'] != null ||
          authority is! Map ||
          authority['online_requested'] != true) {
        return;
      }
      await refresher.refresh(
        deviceId: authority['device_id'] as String,
        mode: CashierConnectionMode.online,
      );
    } catch (_) {
      // The server expires the heartbeat. Keep saved work and its permissions.
      // An explicit confirmed offline bootstrap is required before local writes.
    } finally {
      _running = false;
    }
  }

  void stop() {
    _stopped = true;
    _timer?.cancel();
    _timer = null;
  }
}
