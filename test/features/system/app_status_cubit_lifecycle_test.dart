import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/system/domain/entities/app_status_entity.dart';
import 'package:play_spot_dashboard/features/system/domain/usecases/get_app_status_usecase.dart';
import 'package:play_spot_dashboard/features/system/presentation/cubit/app_status_cubit.dart';

class _GetStatus extends Mock implements GetAppStatusUseCase {}
class _Client extends Mock implements SupabaseClient {}
class _Channel extends Mock implements RealtimeChannel {}

void main() {
  setUpAll(() {
    registerFallbackValue((PostgresChangePayload _) {});
  });

  testWidgets('watch initialization is idempotent and close releases polling/channel', (tester) async {
    final getStatus = _GetStatus();
    final client = _Client();
    final channel = _Channel();
    var reads = 0;
    when(() => getStatus()).thenAnswer((_) async {
      reads++;
      return const Right(AppStatusEntity());
    });
    when(() => client.channel(any())).thenReturn(channel);
    when(() => channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'app_status',
      callback: any(named: 'callback'),
    )).thenReturn(channel);
    when(() => channel.subscribe()).thenReturn(channel);
    final removal = Completer<String>();
    when(() => client.removeChannel(channel)).thenAnswer((_) => removal.future);
    final cubit = AppStatusCubit(getAppStatusUseCase: getStatus, supabaseClient: client);
    cubit.initAppStatusWatch();
    cubit.initAppStatusWatch();
    await tester.pump();
    expect(reads, 1);
    await tester.pump(const Duration(seconds: 60));
    expect(reads, 2);
    final closing = cubit.close();
    await tester.pump();
    expect(cubit.isClosed, isTrue);
    cubit.initAppStatusWatch();
    await tester.pump(const Duration(seconds: 120));
    expect(reads, 2);
    verify(() => client.channel(any())).called(1);
    verify(() => client.removeChannel(channel)).called(1);
    removal.complete('ok');
    await closing;
  });

  test('late status fetch after close cannot emit', () async {
    final getStatus = _GetStatus();
    final response = Completer<Either<Failure, AppStatusEntity>>();
    when(() => getStatus()).thenAnswer((_) => response.future);
    final cubit = AppStatusCubit(getAppStatusUseCase: getStatus, supabaseClient: _Client());
    final reading = cubit.checkAppStatus();
    await cubit.close();
    response.complete(const Right(AppStatusEntity()));
    await expectLater(reading, completes);
  });
}
