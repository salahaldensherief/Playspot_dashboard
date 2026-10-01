import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/cashier_authority_refresher.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/cashier_authority_transport.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/entities/cashier_connection_mode.dart';
import 'support/authority_harness.dart';

class _Transport extends Mock implements CashierAuthorityTransport {}

void main() {
  late AuthorityHarness harness;
  late _Transport transport;
  late CashierAuthorityRefresher refresher;
  setUp(() async {
    harness = AuthorityHarness();
    await harness.open();
    transport = _Transport();
    refresher = CashierAuthorityRefresher(
      transport: transport,
      store: harness.store,
    );
  });
  tearDown(() => harness.dispose());
  Future<Map<String, dynamic>> refresh(CashierConnectionMode mode) =>
      refresher.refresh(deviceId: harness.deviceId, mode: mode);
  void stub(
    CashierConnectionMode mode,
    Future<Map<String, dynamic>> Function() action,
  ) {
    when(
      () => transport.refresh(
        loungeId: harness.current['lounge_id'],
        deviceId: harness.deviceId,
        mode: mode,
      ),
    ).thenAnswer((_) => action());
  }

  test(
    'online then offline requests serialize and persist final offline state',
    () async {
      final first = Completer<Map<String, dynamic>>();
      final started = Completer<void>();
      final calls = <CashierConnectionMode>[];
      stub(CashierConnectionMode.online, () {
        calls.add(CashierConnectionMode.online);
        started.complete();
        return first.future;
      });
      stub(CashierConnectionMode.offline, () async {
        calls.add(CashierConnectionMode.offline);
        return harness.previous;
      });
      final online = refresh(CashierConnectionMode.online);
      final offline = refresh(CashierConnectionMode.offline);
      await started.future;
      expect(calls, [CashierConnectionMode.online]);
      final response = harness.previous..['online_requested'] = true;
      response['heartbeat_expires_at'] = harness.now
          .add(const Duration(seconds: 90))
          .toIso8601String();
      first.complete(response);
      await online;
      await offline;
      expect(calls, [
        CashierConnectionMode.online,
        CashierConnectionMode.offline,
      ]);
      expect(
        (await harness.journal.read())['authority']['online_requested'],
        false,
      );
    },
  );
  test(
    'stop rejects an in-flight response and queued requests without writes',
    () async {
      final first = Completer<Map<String, dynamic>>();
      final started = Completer<void>();
      stub(CashierConnectionMode.offline, () {
        started.complete();
        return first.future;
      });
      final before = await harness.journal.read();
      final active = expectLater(
        refresh(CashierConnectionMode.offline),
        throwsStateError,
      );
      final queued = expectLater(
        refresh(CashierConnectionMode.offline),
        throwsStateError,
      );
      await started.future;
      refresher.stop();
      first.complete(harness.previous);
      await active;
      await queued;
      expect(await harness.journal.read(), before);
      verify(
        () => transport.refresh(
          loungeId: harness.current['lounge_id'],
          deviceId: harness.deviceId,
          mode: CashierConnectionMode.offline,
        ),
      ).called(1);
    },
  );
  test(
    'transport failure preserves data and does not poison the next refresh',
    () async {
      stub(
        CashierConnectionMode.offline,
        () => Future.error(StateError('offline_cashier.authority_unavailable')),
      );
      await expectLater(
        refresh(CashierConnectionMode.offline),
        throwsStateError,
      );
      expect((await harness.journal.read())['authority'], null);
      stub(CashierConnectionMode.offline, () async => harness.previous);
      expect(await refresh(CashierConnectionMode.offline), harness.previous);
    },
  );
  test(
    'invalid grant preserves data and does not poison the next refresh',
    () async {
      stub(
        CashierConnectionMode.offline,
        () async => harness.previous..['profile_banned'] = true,
      );
      await expectLater(
        refresh(CashierConnectionMode.offline),
        throwsFormatException,
      );
      stub(CashierConnectionMode.offline, () async => harness.previous);
      await refresh(CashierConnectionMode.offline);
      expect((await harness.journal.read())['authority'], harness.previous);
    },
  );
  test('closed journal rejects a late response', () async {
    final first = Completer<Map<String, dynamic>>();
    final started = Completer<void>();
    stub(CashierConnectionMode.offline, () {
      started.complete();
      return first.future;
    });
    final response = expectLater(
      refresh(CashierConnectionMode.offline),
      throwsStateError,
    );
    await started.future;
    await harness.journal.close();
    first.complete(harness.previous);
    await response;
    await harness.reopen();
    expect((await harness.journal.read())['authority'], null);
  });
}
