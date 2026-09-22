import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/core/utils/paginated_result.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/entities/tournament_audit_log_entity.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/entities/tournament_entity.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/repositories/tournament_repository.dart';
import 'package:play_spot_dashboard/core/services/location_service.dart';
import 'package:play_spot_dashboard/core/services/storage_service.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/usecases/tournament_match_usecases.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/usecases/tournament_participant_usecases.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/usecases/tournament_usecases.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/tournament_cubit.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/tournament_state.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

class MockLocationService extends Mock implements LocationService {}

class MockStorageService extends Mock implements StorageService {}

class FakeTournamentEntity extends Fake implements TournamentEntity {}

void main() {
  late MockTournamentRepository mockRepository;
  late MockLocationService mockLocationService;
  late MockStorageService mockStorageService;
  late TournamentCubit cubit;

  final tTournament = TournamentEntity(
    id: 't-1',
    title: 'Test Tournament',
    gameTitle: 'EA FC 25',
    treeSize: 16,
    status: TournamentStatus.draft,
    entryFee: 50.0,
    prizePool: 500.0,
    startDate: DateTime(2025, 1, 1),
    endDate: DateTime(2025, 1, 2),
    registrationDeadline: DateTime(2024, 12, 30),
    minPlayers: 4,
    maxPlayers: 16,
  );

  setUpAll(() {
    registerFallbackValue(FakeTournamentEntity());
  });

  setUp(() {
    mockRepository = MockTournamentRepository();
    mockLocationService = MockLocationService();
    mockStorageService = MockStorageService();
    when(() => mockLocationService.getCurrentPosition()).thenAnswer((_) async => null);

    cubit = TournamentCubit(
      getTournamentsUseCase: GetTournamentsUseCase(mockRepository),
      createTournamentUseCase: CreateTournamentUseCase(mockRepository),
      updateTournamentUseCase: UpdateTournamentUseCase(mockRepository),
      saveTournamentPrizesUseCase: SaveTournamentPrizesUseCase(mockRepository),
      publishTournamentUseCase: PublishTournamentUseCase(mockRepository),
      cancelTournamentUseCase: CancelTournamentUseCase(mockRepository),
      deleteDraftTournamentUseCase: DeleteDraftTournamentUseCase(mockRepository),
      deleteTournamentUseCase: DeleteTournamentUseCase(mockRepository),
      completeTournamentUseCase: CompleteTournamentUseCase(mockRepository),
      awardPrizesUseCase: AwardPrizesUseCase(mockRepository),
      getTournamentAuditLogsUseCase: GetTournamentAuditLogsUseCase(mockRepository),
      watchDisputedMatchesUseCase: WatchDisputedMatchesUseCase(mockRepository),
      getParticipantsUseCase: GetTournamentParticipantsUseCase(mockRepository),
      approvePaymentUseCase: ApproveParticipantPaymentUseCase(mockRepository),
      rejectPaymentUseCase: RejectParticipantPaymentUseCase(mockRepository),
      recordCashPaymentUseCase: RecordCashPaymentUseCase(mockRepository),
      promoteWaitlistUseCase: PromoteWaitlistUseCase(mockRepository),
      checkInParticipantUseCase: CheckInParticipantUseCase(mockRepository),
      withdrawParticipantUseCase: WithdrawParticipantUseCase(mockRepository),
      drawBracketUseCase: DrawBracketUseCase(mockRepository),
      getMatchesUseCase: GetTournamentMatchesUseCase(mockRepository),
      startMatchUseCase: StartMatchUseCase(mockRepository),
      resolveDisputeUseCase: ResolveDisputeUseCase(mockRepository),
      locationService: mockLocationService,
      storageService: mockStorageService,
    );
  });

  tearDown(() {
    cubit.close();
  });

  test('initial state should be TournamentState()', () {
    expect(cubit.state, equals(const TournamentState()));
  });

  test('loadTournaments emits success state with loaded list', () async {
    when(() => mockRepository.getTournaments(loungeId: any(named: 'loungeId'), status: any(named: 'status')))
        .thenAnswer((_) async => Right([tTournament]));
    when(() => mockRepository.getParticipants(any())).thenAnswer((_) async => const Right([]));
    when(() => mockRepository.getMatches(any())).thenAnswer((_) async => const Right([]));
    when(() => mockRepository.getAuditLogs(any())).thenAnswer((_) async => const Right([]));
    when(() => mockRepository.getTournamentAuditLogsPage(
          tournamentId: any(named: 'tournamentId'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        )).thenAnswer((_) async => Right(PaginatedResult<TournamentAuditLogEntity>(
          items: const [],
          totalCount: 0,
          page: 1,
          pageSize: 20,
        )));
    when(() => mockRepository.watchDisputedMatches(any())).thenAnswer((_) => const Stream.empty());

    await cubit.loadTournaments();

    expect(cubit.state.status, equals(TournamentCubitStatus.success));
    expect(cubit.state.tournaments, equals([tTournament]));
  });

  test('createTournament emits actionSuccess on success', () async {
    when(() => mockRepository.createTournament(any()))
        .thenAnswer((_) async => Right(tTournament));
    when(() => mockRepository.getParticipants(any())).thenAnswer((_) async => const Right([]));
    when(() => mockRepository.getMatches(any())).thenAnswer((_) async => const Right([]));
    when(() => mockRepository.getAuditLogs(any())).thenAnswer((_) async => const Right([]));
    when(() => mockRepository.getTournamentAuditLogsPage(
          tournamentId: any(named: 'tournamentId'),
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        )).thenAnswer((_) async => Right(PaginatedResult<TournamentAuditLogEntity>(
          items: const [],
          totalCount: 0,
          page: 1,
          pageSize: 20,
        )));
    when(() => mockRepository.watchDisputedMatches(any())).thenAnswer((_) => const Stream.empty());

    await cubit.createTournament(tTournament);

    expect(cubit.state.status, equals(TournamentCubitStatus.actionSuccess));
    expect(cubit.state.tournaments, contains(tTournament));
  });

  test('deleteDraftTournament handles failure correctly', () async {
    when(() => mockRepository.deleteDraftTournament(any()))
        .thenAnswer((_) async => const Left(ServerFailure('Cannot delete draft with participants')));

    await cubit.deleteDraftTournament('t-1');

    expect(cubit.state.status, equals(TournamentCubitStatus.failure));
    expect(cubit.state.errorMessage, equals('Cannot delete draft with participants'));
  });
}
