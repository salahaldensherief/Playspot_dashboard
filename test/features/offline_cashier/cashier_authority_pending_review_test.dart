import 'package:flutter_test/flutter_test.dart';
import 'support/authority_harness.dart';

void main() {
  late AuthorityHarness harness;
  setUp(() async {
    harness = AuthorityHarness();
    await harness.open();
  });
  tearDown(() => harness.dispose());
  test(
    'renewal cannot overwrite immutable history from changed cached grant facts',
    () async {
      await harness.seedPending();
      await harness.journal.mutate(
        (state) =>
            state['authority']['permissions']['billing_checkout'] = false,
      );
      final before = await harness.journal.read();
      await expectLater(
        harness.install(harness.current),
        throwsFormatException,
      );
      expect(await harness.journal.read(), before);
    },
  );
  for (final field in [
    'actor_id',
    'lounge_id',
    'device_id',
    'permit_id',
    'kind',
    'occurred_at',
  ]) {
    test(
      'queued event with changed $field remains saved but requires review after renewal',
      () async {
        await harness.seedPending();
        await harness.journal.mutate(
          (state) => state['outbox'][0][field] = field == 'occurred_at'
              ? DateTime.fromMillisecondsSinceEpoch(
                  harness.previous['expires_ms'],
                  isUtc: true,
                ).toIso8601String()
              : 'changed',
        );
        final before = await harness.journal.read();
        await harness.install(harness.current);
        final after = await harness.journal.read();
        expect(after['authority_review_required'], true);
        expect(after['outbox'], before['outbox']);
        expect(after['next_sequence'], before['next_sequence']);
        expect(after['bookings'], before['bookings']);
      },
    );
  }
  test(
    'grant without original booking permission cannot authorize queued reservation',
    () async {
      await harness.seedPending();
      await harness.journal.mutate((state) {
        state['authority']['permissions']['bookings.manage'] = false;
        state['authority_history'][harness
                .previous['permit_id']]['permissions']['bookings.manage'] =
            false;
      });
      final before = await harness.journal.read();
      await harness.install(harness.current);
      final after = await harness.journal.read();
      expect(after['authority_review_required'], true);
      expect(after['outbox'], before['outbox']);
    },
  );
}
