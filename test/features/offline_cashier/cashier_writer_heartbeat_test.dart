import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/cashier_writer_heartbeat.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/cashier_authority_refresher.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/entities/cashier_connection_mode.dart';
import 'support/authority_harness.dart';

class _Refresh extends Mock implements CashierAuthorityRefresher {}

void main() {
  late AuthorityHarness h;
  late _Refresh refresh;
  late CashierWriterHeartbeat heartbeat;
  setUp(() async {
    h = AuthorityHarness();
    await h.open();
    await h.install(h.previous);
    refresh = _Refresh();
    heartbeat = CashierWriterHeartbeat(h.journal, refresh);
  });
  tearDown(() async {
    heartbeat.stop();
    await h.dispose();
  });
  test('offline preparation never sends an online heartbeat', () async {
    await h.journal.mutate((s) => s['bootstrap'] = {});
    await heartbeat.tick();
    verifyNever(
      () => refresh.refresh(
        deviceId: h.deviceId,
        mode: CashierConnectionMode.online,
      ),
    );
  });
  test('pending release prevents automatic device reclaim', () async {
    await h.journal.mutate((s) {
      s['bootstrap'] = {};
      s['authority']['online_requested'] = true;
      s['writer_release'] = {'status': 'pending'};
    });
    await heartbeat.tick();
    verifyNever(
      () => refresh.refresh(
        deviceId: h.deviceId,
        mode: CashierConnectionMode.online,
      ),
    );
  });
  test(
    'online lease refresh is single flight and preserves saved data after failure',
    () async {
      await h.journal.mutate((s) {
        s['bootstrap'] = {};
        s['authority']['online_requested'] = true;
      });
      final before = await h.journal.read();
      final pending = Completer<Map<String, dynamic>>();
      when(
        () => refresh.refresh(
          deviceId: h.deviceId,
          mode: CashierConnectionMode.online,
        ),
      ).thenAnswer((_) => pending.future);
      final first = heartbeat.tick();
      await Future<void>.delayed(Duration.zero);
      await heartbeat.tick();
      verify(
        () => refresh.refresh(
          deviceId: h.deviceId,
          mode: CashierConnectionMode.online,
        ),
      ).called(1);
      pending.completeError(TimeoutException('Network'));
      await first;
      expect(await h.journal.read(), before);
    },
  );
  test('stopped heartbeat performs no request', () async {
    heartbeat.stop();
    await heartbeat.tick();
    verifyNever(
      () => refresh.refresh(
        deviceId: h.deviceId,
        mode: CashierConnectionMode.online,
      ),
    );
  });
}
