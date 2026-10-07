import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/loyalty/data/datasources/loyalty_remote_data_source_impl.dart';
import 'package:play_spot_dashboard/features/loyalty/data/repositories/loyalty_repository_impl.dart';
import 'package:play_spot_dashboard/features/loyalty/domain/usecases/loyalty_usecases.dart';
import 'package:play_spot_dashboard/features/loyalty/presentation/cubit/loyalty_cubit.dart';
import 'package:play_spot_dashboard/features/loyalty/presentation/cubit/loyalty_state.dart';

LoyaltyCubit makeCubit(SupabaseClient client) {
  final repository = LoyaltyRepositoryImpl(LoyaltyRemoteDataSourceImpl(client));
  return LoyaltyCubit(
    getLoyaltyStatsUseCase: GetLoyaltyStatsUseCase(repository),
    getReferralsUseCase: GetReferralsUseCase(repository),
    getLoyaltyTasksUseCase: GetLoyaltyTasksUseCase(repository),
    updateLoyaltyTaskUseCase: UpdateLoyaltyTaskUseCase(repository),
    getLoyaltyLevelsUseCase: GetLoyaltyLevelsUseCase(repository),
    updateLoyaltyLevelUseCase: UpdateLoyaltyLevelUseCase(repository),
    adjustUserPointsUseCase: AdjustUserPointsUseCase(repository),
    getPointsTransactionsPageUseCase: GetPointsTransactionsPageUseCase(
      repository,
    ),
    getRedemptionOptionsUseCase: GetRedemptionOptionsUseCase(repository),
    createRedemptionOptionUseCase: CreateRedemptionOptionUseCase(repository),
    updateRedemptionOptionUseCase: UpdateRedemptionOptionUseCase(repository),
    deleteRedemptionOptionUseCase: DeleteRedemptionOptionUseCase(repository),
  );
}

void main() {
  late List<http.Request> requests;
  late SupabaseClient client;
  late LoyaltyRemoteDataSourceImpl source;
  var aggregateFails = true;
  var referralsFail = false;
  var referralsEmpty = true;
  setUp(() {
    requests = [];
    aggregateFails = true;
    referralsFail = false;
    referralsEmpty = true;
    client = SupabaseClient(
      'https://example.invalid',
      'test-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        var status = 200;
        Object? body = [];
        if (path.endsWith('/get_loyalty_dashboard_stats')) {
          if (aggregateFails) {
            status = 404;
            body = {'code': 'PGRST202', 'message': 'Missing aggregate RPC'};
          } else {
            body = {
              'total_added_points': 0,
              'user_count_by_level': {},
              'total_referrals': 0,
              'completed_referrals': 0,
              'total_referral_points': 0,
            };
          }
        } else if (path.endsWith('/get_loyalty_referrals')) {
          if (referralsFail) {
            status = 403;
            body = {'code': '42501', 'message': 'permission denied'};
          } else if (!referralsEmpty) {
            body = [
              {
                'id': 'referral-1',
                'referrer_id': 'u1',
                'referred_id': 'u2',
                'status': 'completed',
                'reward_claimed': true,
                'created_at': '2026-10-02T10:00:00Z',
                'referrer': {
                  'id': 'u1',
                  'full_name': 'Fixture customer',
                  'email': 'fixture@example.invalid',
                },
                'referred': {
                  'id': 'u2',
                  'full_name': 'Invited customer',
                  'email': 'invited@example.invalid',
                },
              },
            ];
          }
        } else if (path.endsWith('/loyalty_missions')) {
          body = request.method == 'PATCH'
              ? {'id': 'mission-1'}
              : [
                  {
                    'id': 'mission-1',
                    'title_ar': 'مهمة حقيقية',
                    'title_en': 'Actual mission',
                    'reward_points': 52,
                    'is_active': true,
                  },
                ];
        }
        return http.Response(
          jsonEncode(body),
          status,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    source = LoyaltyRemoteDataSourceImpl(client);
  });
  tearDown(() async => client.dispose());

  test(
    'missing aggregate remains an error without invented table totals',
    () async {
      await expectLater(
        source.getLoyaltyStats(),
        throwsA(isA<PostgrestException>()),
      );
      expect(requests, hasLength(1));
    },
  );
  test('empty referral table remains empty', () async {
    expect(await source.getReferrals(), isEmpty);
    expect(requests, hasLength(1));
  });
  test('denied referrals never turn into fake customers', () async {
    referralsFail = true;
    await expectLater(
      source.getReferrals(),
      throwsA(isA<PostgrestException>()),
    );
    expect(requests, hasLength(1));
  });
  test(
    'canonical referral IDs and reward flag preserve unknown points',
    () async {
      referralsEmpty = false;
      final referral = (await source.getReferrals(userId: 'u1')).single;
      expect(referral.inviterId, 'u1');
      expect(referral.inviteeId, 'u2');
      expect(referral.inviterName, 'Fixture customer');
      expect(referral.rewardIssued, isTrue);
      expect(referral.inviterPoints, isNull);
      expect(referral.inviteePoints, isNull);
      expect(
        requests.single.url.path,
        '/rest/v1/rpc/get_loyalty_referrals',
      );
      expect(jsonDecode(requests.single.body)['p_user_query'], 'u1');
    },
  );
  test(
    'mission schema maps reward_points and does not fabricate completion counts',
    () async {
      final task = (await source.getTasks()).single;
      expect(task.pointsReward, 52);
      expect(task.completedCount, isNull);
      expect(requests.single.url.path, '/rest/v1/loyalty_missions');
    },
  );
  test(
    'editing mission metadata uses reward_points, not a completion or points ledger write',
    () async {
      await source.updateTask('mission-1', {
        'points_reward': 60,
        'title_ar': 'عنوان',
      });
      expect(jsonDecode(requests.single.body), {
        'reward_points': 60,
        'title_ar': 'عنوان',
      });
      expect(requests.single.url.path, '/rest/v1/loyalty_missions');
      expect(requests.single.method, 'PATCH');
      await expectLater(
        source.updateTask('mission-1', {'completed_count': 999}),
        throwsArgumentError,
      );
      expect(requests, hasLength(1));
    },
  );
  test(
    'unavailable statistics do not hide working missions and other sections',
    () async {
      final cubit = makeCubit(client);
      addTearDown(cubit.close);
      await cubit.loadLoyaltyData();
      expect(cubit.state.status, LoyaltyStatus.success);
      expect(cubit.state.stats, isNull);
      expect(cubit.state.sectionErrors.keys, ['stats']);
      expect(cubit.state.tasks.single.pointsReward, 52);
      expect(cubit.state.referrals, isEmpty);
    },
  );
  test('closing during a load never emits afterward', () async {
    final pending = Completer<http.Response>();
    final delayedClient = SupabaseClient(
      'https://example.invalid',
      'test-key',
      httpClient: MockClient((request) async {
        if (request.url.path.contains('/rpc/')) return pending.future;
        return http.Response(
          '[]',
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    addTearDown(delayedClient.dispose);
    final cubit = makeCubit(delayedClient);
    final load = cubit.loadLoyaltyData();
    await Future<void>.delayed(Duration.zero);
    await cubit.close();
    pending.complete(
      http.Response(
        '{"code":"PGRST202","message":"missing"}',
        404,
        headers: {'content-type': 'application/json'},
        request: http.Request(
          'POST',
          Uri.parse(
            'https://example.invalid/rest/v1/rpc/get_loyalty_dashboard_stats',
          ),
        ),
      ),
    );
    await load;
    expect(cubit.isClosed, isTrue);
  });
}
