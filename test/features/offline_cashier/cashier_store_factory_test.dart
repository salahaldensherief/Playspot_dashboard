import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/cashier_store_factory_impl.dart';
import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/offline_key_vault.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/entities/cashier_connection_mode.dart';
import 'package:play_spot_dashboard/features/offline_cashier/domain/repositories/offline_cashier_repository.dart';
import 'support/authority_harness.dart';

class _Keys extends Mock implements OfflineKeyVault {}

void main() {
  late AuthorityHarness harness;
  late SupabaseClient client;
  late CashierStoreFactoryImpl factory;
  late Future<http.Response> Function(http.Request) respond;
  late List<http.Request> requests;
  Map<String, dynamic> wire() => harness.current;
  DateTime clock() => DateTime.fromMillisecondsSinceEpoch(
    harness.current['server_time_ms'],
    isUtc: true,
  );

  Future<void> login(
    String id, {
    String token = 'synthetic-access-token',
  }) async {
    await client.auth.recoverSession(
      jsonEncode({
        'access_token': token,
        'refresh_token': 'synthetic-refresh-token',
        'token_type': 'bearer',
        'user': {
          'id': id,
          'aud': 'authenticated',
          'app_metadata': {},
          'user_metadata': {},
          'created_at': '2026-01-01T00:00:00Z',
        },
      }),
    );
  }

  Future<OfflineCashierRepository> open() => factory.open(
    actorId: harness.current['actor_id'],
    loungeId: harness.current['lounge_id'],
  );
  Future<Either<Failure, Map<String, dynamic>>> refresh(
    OfflineCashierRepository repository,
  ) => repository.refreshAuthority(
    deviceId: harness.deviceId,
    mode: CashierConnectionMode.offline,
  );
  setUp(() async {
    harness = AuthorityHarness();
    await harness.open();
    requests = [];
    respond = (request) async =>
        http.Response(jsonEncode(wire()), 200, request: request);
    client = SupabaseClient(
      'https://offline-fixture.invalid',
      'public-fixture-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/logout')) {
          return http.Response('', 204, request: request);
        }
        requests.add(request);
        return respond(request);
      }),
    );
    await login(harness.current['actor_id']);
    factory = CashierStoreFactoryImpl(
      keys: harness,
      client: client,
      clock: clock,
    );
  });
  tearDown(() async {
    await factory.dispose();
    await harness.dispose();
    await client.dispose();
  });

  test(
    'authenticated factory installs renewed grant with preserved pending work',
    () async {
      await harness.seedPending();
      final repository = await open();
      final result = await refresh(repository);
      expect(result.isRight(), true);
      final state = await harness.journal.read();
      expect(state['authority']['permit_id'], harness.current['permit_id']);
      expect(state['outbox'], [harness.pending]);
      expect(state['next_sequence'], 2);
    },
  );
  test(
    'invalid authority maps a localized failure without persistence',
    () async {
      final repository = await open();
      final before = await harness.journal.read();
      respond = (request) async => http.Response(
        jsonEncode(wire()..['profile_banned'] = true),
        200,
        request: request,
      );
      expect(
        await refresh(repository),
        const Left<Failure, Map<String, dynamic>>(
          CacheFailure('offline_cashier.invalid_authority'),
        ),
      );
      expect(await harness.journal.read(), before);
    },
  );
  test(
    'failed HTTP preserves queued work and maps a localized refresh failure',
    () async {
      await harness.seedPending();
      final repository = await open();
      final before = await harness.journal.read();
      respond = (_) async => throw StateError('synthetic transport failure');
      expect(
        await refresh(repository),
        const Left<Failure, Map<String, dynamic>>(
          CacheFailure('offline_cashier.authority_unavailable'),
        ),
      );
      expect(await harness.journal.read(), before);
    },
  );
  for (final transition in ['logout', 'other actor', 'closeAll']) {
    test(
      '$transition invalidates existing repository and preserves encrypted records',
      () async {
        await harness.seedPending();
        final repository = await open();
        final before = await harness.journal.read();
        if (transition == 'logout') await client.auth.signOut();
        if (transition == 'other actor') {
          await login('00000000-0000-0000-0000-000000000001');
        }
        await factory.closeAll();
        expect((await repository.snapshot()).isLeft(), true);
        expect((await refresh(repository)).isLeft(), true);
        expect(requests, isEmpty);
        await harness.reopen();
        expect(await harness.journal.read(), before);
      },
    );
  }
  test(
    'same user relogin opens new repository while old references stay invalid',
    () async {
      await harness.seedPending();
      final repository = await open();
      final before = await harness.journal.read();
      await client.auth.signOut();
      await login(
        harness.current['actor_id'],
        token: 'new-synthetic-access-token',
      );
      final reopened = await open();
      expect(identical(repository, reopened), false);
      expect((await repository.snapshot()).isLeft(), true);
      (await reopened.snapshot()).fold(
        (failure) => fail(failure.message),
        (state) => expect(state, before),
      );
      await harness.reopen();
    },
  );
  test('token refresh does not close the same identity repository', () async {
    final repository = await open();
    await login(
      harness.current['actor_id'],
      token: 'renewed-synthetic-access-token',
    );
    expect(identical(repository, await open()), true);
    expect((await repository.snapshot()).isRight(), true);
  });
  test(
    'same actor sign-in invalidates previous repository without sign-out',
    () async {
      await harness.seedPending();
      final repository = await open();
      final before = await harness.journal.read();
      respond = (request) async => http.Response(
        jsonEncode({
          'access_token': 'new-synthetic-access-token',
          'refresh_token': 'new-synthetic-refresh-token',
          'token_type': 'bearer',
          'user': client.auth.currentUser?.toJson(),
        }),
        200,
        request: request,
      );
      await client.auth.signInWithPassword(
        email: 'fixture@example.invalid',
        password: 'synthetic-password',
      );
      final reopened = await open();
      expect(identical(repository, reopened), false);
      expect((await repository.snapshot()).isLeft(), true);
      (await reopened.snapshot()).fold(
        (failure) => fail(failure.message),
        (state) => expect(state, before),
      );
      await harness.reopen();
    },
  );
  for (final transition in ['logout', 'closeAll']) {
    test('late renewal after $transition cannot replace saved state', () async {
      await harness.seedPending();
      final before = await harness.journal.read();
      final repository = await open();
      final started = Completer<void>();
      final response = Completer<http.Response>();
      respond = (_) {
        started.complete();
        return response.future;
      };
      final pending = refresh(repository);
      await started.future;
      if (transition == 'logout') await client.auth.signOut();
      await factory.closeAll();
      response.complete(
        http.Response(jsonEncode(wire()), 200, request: requests.single),
      );
      expect((await pending).isLeft(), true);
      await harness.reopen();
      expect(await harness.journal.read(), before);
    });
  }
  test(
    'logout during encrypted storage opening cannot hand out old account data',
    () async {
      await harness.seedPending();
      final before = await harness.journal.read();
      await harness.journal.close();
      await factory.dispose();
      final keys = _Keys();
      final started = Completer<void>();
      final encryptionKey = Completer<String?>();
      when(() => keys.read(any())).thenAnswer((_) {
        started.complete();
        return encryptionKey.future;
      });
      factory = CashierStoreFactoryImpl(
        keys: keys,
        client: client,
        clock: clock,
      );
      final opening = expectLater(open(), throwsStateError);
      await started.future;
      await client.auth.signOut();
      encryptionKey.complete(harness.keys.values.single);
      await opening;
      await factory.closeAll();
      await harness.reopen();
      expect(await harness.journal.read(), before);
    },
  );
  test('disposed factory cannot allocate more account storage', () async {
    await factory.dispose();
    await expectLater(open(), throwsStateError);
  });
}
