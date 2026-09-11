import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/entities/tournament_entity.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/repositories/tournament_repository.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/tournament_cubit.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/tournament_state.dart';

class MockTournamentRepository extends Mock implements TournamentRepository {}

void main() {
  late MockTournamentRepository mockRepository;
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

  setUp(() {
    mockRepository = MockTournamentRepository();
    cubit = TournamentCubit(mockRepository);
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
