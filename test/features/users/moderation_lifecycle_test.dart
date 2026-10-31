import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/users/data/datasources/moderation_remote_data_source.dart';
import 'package:play_spot_dashboard/features/users/data/models/user_ban_request_model.dart';
import 'package:play_spot_dashboard/features/users/presentation/cubit/moderation_cubit.dart';
import 'package:play_spot_dashboard/features/users/presentation/cubit/moderation_state.dart';

class _Source extends Mock implements ModerationRemoteDataSource {}

void main() {
  test(
    'duplicate submission shares guard and late completion after disposal is safe',
    () async {
      final source = _Source();
      final pending = Completer<void>();
      when(
        () => source.createBanRequest(
          loungeId: 'venue',
          userId: 'customer',
          reason: 'reason',
        ),
      ).thenAnswer((_) => pending.future);
      final cubit = ModerationCubit(dataSource: source);
      final first = cubit.createBanRequest(
        loungeId: 'venue',
        userId: 'customer',
        reason: 'reason',
      );
      await cubit.createBanRequest(
        loungeId: 'venue',
        userId: 'customer',
        reason: 'reason',
      );
      expect(cubit.state.isSubmitting, isTrue);
      verify(
        () => source.createBanRequest(
          loungeId: 'venue',
          userId: 'customer',
          reason: 'reason',
        ),
      ).called(1);
      await cubit.close();
      pending.complete();
      await first;
    },
  );

  test('late lounge response cannot replace the latest lounge queue', () async {
    final source = _Source();
    final oldRequest = Completer<List<UserBanRequestModel>>();
    when(
      () => source.getLoungeBanRequests('old'),
    ).thenAnswer((_) => oldRequest.future);
    when(() => source.getLoungeBanRequests('new')).thenAnswer((_) async => []);
    final cubit = ModerationCubit(dataSource: source);
    addTearDown(cubit.close);
    final first = cubit.loadLoungeBanRequests('old');
    await cubit.loadLoungeBanRequests('new');
    oldRequest.complete([
      UserBanRequestModel(
        id: 'old-report',
        loungeId: 'old',
        userId: 'customer',
        reason: 'reason',
        createdAt: DateTime.utc(2026, 10, 4),
      ),
    ]);
    await first;
    expect(cubit.state.status, ModerationStatus.success);
    expect(cubit.state.banRequests, isEmpty);
  });

  test(
    'denied mutation has localized failure key, no fabricated success, and can retry',
    () async {
      final source = _Source();
      when(() => source.suspendLounge('venue', reason: 'reason')).thenThrow(
        const PostgrestException(
          message: 'private database detail',
          code: '42501',
        ),
      );
      final cubit = ModerationCubit(dataSource: source);
      addTearDown(cubit.close);
      await cubit.suspendLounge('venue', reason: 'reason');
      expect(cubit.state.errorMessage, 'moderation_permission_denied');
      expect(cubit.state.successMessage, isNull);
      expect(cubit.state.isSubmitting, isFalse);
      when(
        () => source.suspendLounge('venue', reason: 'reason'),
      ).thenAnswer((_) async {});
      await cubit.suspendLounge('venue', reason: 'reason');
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.successMessage, 'moderation_lounge_suspended');
    },
  );

  test(
    'missing queue service is a failure, not an empty successful queue',
    () async {
      final source = _Source();
      when(() => source.getPendingBanRequests()).thenThrow(
        const PostgrestException(
          message: 'private schema details',
          code: 'PGRST202',
        ),
      );
      final cubit = ModerationCubit(dataSource: source);
      addTearDown(cubit.close);
      await cubit.loadPendingBanRequests();
      expect(cubit.state.status, ModerationStatus.error);
      expect(cubit.state.errorMessage, 'moderation_service_unavailable');
    },
  );
}
