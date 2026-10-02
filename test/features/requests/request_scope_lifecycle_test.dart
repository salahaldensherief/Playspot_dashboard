import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/core/audio/audio_service.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/core/utils/paginated_result.dart';
import 'package:play_spot_dashboard/features/requests/domain/entities/client_request_entity.dart';
import 'package:play_spot_dashboard/features/requests/domain/repositories/client_requests_repository.dart';
import 'package:play_spot_dashboard/features/requests/domain/usecases/get_active_lounge_requests_page_usecase.dart';
import 'package:play_spot_dashboard/features/requests/domain/usecases/mark_request_as_attended_usecase.dart';
import 'package:play_spot_dashboard/features/requests/domain/usecases/watch_client_requests_usecase.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_cubit.dart';
import 'package:play_spot_dashboard/features/requests/presentation/client_requests_state.dart';

class _Repository extends Mock implements ClientRequestsRepository {}

class _Audio extends Mock implements AudioService {}

ClientRequestEntity request(String id, String lounge) => ClientRequestEntity(
  id: id,
  loungeId: lounge,
  titleAr: '',
  titleEn: '',
  bodyAr: '',
  bodyEn: '',
  type: ClientRequestType.callStaff,
  createdAt: DateTime.utc(2026, 10, 2),
);
PaginatedResult<ClientRequestEntity> page(String id, String lounge) =>
    PaginatedResult(
      items: [request(id, lounge)],
      totalCount: 1,
      page: 1,
      pageSize: 20,
    );

void main() {
  late _Repository repository;
  late _Audio audio;
  late ClientRequestsCubit cubit;
  final controllers = <StreamController<List<ClientRequestEntity>>>[];
  setUp(() {
    repository = _Repository();
    audio = _Audio();
    when(() => audio.stopUrgentAlertSound()).thenAnswer((_) async {});
    cubit = ClientRequestsCubit(
      watchClientRequestsUseCase: WatchClientRequestsUseCase(repository),
      markRequestAsAttendedUseCase: MarkRequestAsAttendedUseCase(repository),
      getActiveLoungeRequestsPageUseCase: GetActiveLoungeRequestsPageUseCase(
        repository,
      ),
      audioService: audio,
    );
  });
  tearDown(() async {
    await cubit.close();
    for (final controller in controllers) {
      await controller.close();
    }
    controllers.clear();
  });
  StreamController<List<ClientRequestEntity>> watch(String lounge) {
    final controller = StreamController<List<ClientRequestEntity>>();
    controllers.add(controller);
    when(
      () => repository.watchClientRequests(loungeId: lounge),
    ).thenAnswer((_) => controller.stream);
    return controller;
  }

  test(
    'switching lounge clears private requests before new data arrives',
    () async {
      final a = watch('a');
      watch('b');
      cubit.startWatchingRequests(loungeId: 'a');
      a.add([request('sc_old', 'a')]);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.requests.single.loungeId, 'a');
      cubit.startWatchingRequests(loungeId: 'b');
      expect(cubit.state.status, ClientRequestsStatus.loading);
      expect(cubit.state.requests, isEmpty);
    },
  );
  test('page from old lounge cannot overwrite a new lounge stream', () async {
    final pending =
        Completer<Either<Failure, PaginatedResult<ClientRequestEntity>>>();
    when(
      () => repository.getActiveLoungeRequestsPage(
        loungeId: 'a',
        page: 1,
        pageSize: 20,
      ),
    ).thenAnswer((_) => pending.future);
    final loading = cubit.fetchActiveRequestsPage(loungeId: 'a');
    final b = watch('b');
    cubit.startWatchingRequests(loungeId: 'b');
    b.add([request('sc_new', 'b')]);
    await Future<void>.delayed(Duration.zero);
    pending.complete(Right(page('sc_old', 'a')));
    await loading;
    expect(cubit.state.requests.single.id, 'sc_new');
  });
  test('older pagination reply cannot overwrite latest page request', () async {
    final first =
        Completer<Either<Failure, PaginatedResult<ClientRequestEntity>>>();
    when(
      () => repository.getActiveLoungeRequestsPage(
        loungeId: 'a',
        page: 1,
        pageSize: 20,
      ),
    ).thenAnswer((_) => first.future);
    when(
      () => repository.getActiveLoungeRequestsPage(
        loungeId: 'a',
        page: 2,
        pageSize: 20,
      ),
    ).thenAnswer((_) async => Right(page('latest', 'a')));
    final old = cubit.fetchActiveRequestsPage(loungeId: 'a');
    await cubit.fetchActiveRequestsPage(loungeId: 'a', page: 2);
    first.complete(Right(page('old', 'a')));
    await old;
    expect(cubit.state.requests.single.id, 'latest');
  });
  test(
    'failed attendance in old lounge does not restore its requests',
    () async {
      final a = watch('a');
      final b = watch('b');
      cubit.startWatchingRequests(loungeId: 'a');
      a.add([request('sc_old', 'a')]);
      await Future<void>.delayed(Duration.zero);
      final pending = Completer<Either<Failure, void>>();
      when(
        () => repository.markRequestAsAttended('sc_old', isCanteenOrder: false),
      ).thenAnswer((_) => pending.future);
      final attending = cubit.markAsAttended('sc_old');
      cubit.startWatchingRequests(loungeId: 'b');
      b.add([request('sc_new', 'b')]);
      await Future<void>.delayed(Duration.zero);
      pending.complete(const Left(ServerFailure('denied')));
      await attending;
      expect(cubit.state.status, ClientRequestsStatus.success);
      expect(cubit.state.requests.single.id, 'sc_new');
    },
  );
  test(
    'stopping the lounge cancels its stream and clears private state',
    () async {
      final a = watch('a');
      cubit.startWatchingRequests(loungeId: 'a');
      a.add([request('sc_old', 'a')]);
      await Future<void>.delayed(Duration.zero);
      cubit.stopWatchingRequests();
      expect(cubit.watchedEntityId, isNull);
      expect(cubit.state.requests, isEmpty);
      expect(cubit.state.status, ClientRequestsStatus.initial);
      expect(a.hasListener, isFalse);
    },
  );
  test(
    'page completing after logout cannot repopulate private requests',
    () async {
      final pending =
          Completer<Either<Failure, PaginatedResult<ClientRequestEntity>>>();
      when(
        () => repository.getActiveLoungeRequestsPage(
          loungeId: 'a',
          page: 1,
          pageSize: 20,
        ),
      ).thenAnswer((_) => pending.future);
      final loading = cubit.fetchActiveRequestsPage(loungeId: 'a');
      cubit.stopWatchingRequests();
      pending.complete(Right(page('sc_old', 'a')));
      await loading;
      expect(cubit.state.requests, isEmpty);
      expect(cubit.state.status, ClientRequestsStatus.initial);
    },
  );
}
