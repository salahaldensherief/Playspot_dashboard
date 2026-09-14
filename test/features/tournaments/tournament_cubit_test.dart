import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/core/services/location_service.dart';
import 'package:play_spot_dashboard/core/services/storage_service.dart';
import 'package:play_spot_dashboard/core/utils/paginated_result.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/entities/tournament_audit_log_entity.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/entities/tournament_entity.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/entities/tournament_match_entity.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/entities/tournament_participant_entity.dart';
import 'package:play_spot_dashboard/features/tournaments/domain/repositories/tournament_repository.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/tournament_cubit.dart';
import 'package:play_spot_dashboard/features/tournaments/presentation/tournament_state.dart';

class FakeLocationService implements LocationService {
  @override
  Future<bool> checkPermissions() async => true;

  @override
  Future<Position?> getCurrentPosition() async => null;

  @override
  Future<String?> getCityFromPosition(Position position, BuildContext context) async => null;
}

class FakeStorageService implements StorageService {
  @override
  Future<String> uploadLoungeImage(Uint8List fileBytes, String fileName, String loungeId) async => '';
  @override
  Future<List<String>> uploadLoungeImages(List<Uint8List> filesBytes, List<String> fileNames, String loungeId) async => [];
  @override
  Future<String> uploadRoomImage(Uint8List fileBytes, String fileName, String loungeId) async => '';
  @override
  Future<List<String>> uploadRoomImages(List<Uint8List> filesBytes, List<String> fileNames, String loungeId) async => [];
  @override
  Future<String> uploadTournamentBanner(Uint8List fileBytes, String fileName, String tournamentId) async => 'http://banner.url';
}

class FakeTournamentRepository implements TournamentRepository {
  Either<Failure, List<TournamentEntity>> getTournamentsResult = const Right([]);
  Either<Failure, TournamentEntity>? createTournamentResult;
  Either<Failure, void>? deleteDraftResult;

  @override
  Future<Either<Failure, List<TournamentEntity>>> getTournaments({
    double? latitude,
    double? longitude,
    String? loungeId,
    String? status,
  }) async => getTournamentsResult;

  @override
  Future<Either<Failure, TournamentEntity>> createTournament(TournamentEntity tournament) async {
    return createTournamentResult ?? Right(tournament);
  }

  @override
  Future<Either<Failure, void>> deleteDraftTournament(String tournamentId) async {
    return deleteDraftResult ?? const Right(null);
  }

  @override
  Future<Either<Failure, TournamentEntity>> updateTournament(TournamentEntity tournament) async => Right(tournament);

  @override
  Future<Either<Failure, void>> publishTournament(String tournamentId) async => const Right(null);

  @override
  Future<Either<Failure, void>> cancelTournament(String tournamentId, String reason) async => const Right(null);

  @override
  Future<Either<Failure, List<TournamentParticipantEntity>>> getParticipants(String tournamentId) async => const Right([]);

  @override
  Future<Either<Failure, void>> approvePayment(String participantId) async => const Right(null);

  @override
  Future<Either<Failure, void>> rejectPayment(String participantId, String reason) async => const Right(null);

  @override
  Future<Either<Failure, void>> recordCashPayment(String participantId) async => const Right(null);

  @override
  Future<Either<Failure, void>> checkInParticipant(String participantId) async => const Right(null);

  @override
  Future<Either<Failure, List<TournamentMatchEntity>>> drawBracket(String tournamentId) async => const Right([]);

  @override
  Future<Either<Failure, List<TournamentMatchEntity>>> getMatches(String tournamentId) async => const Right([]);

  @override
  Future<Either<Failure, void>> startMatch(String matchId, {String? roomId}) async => const Right(null);

  @override
  Future<Either<Failure, void>> resolveDispute(
    String matchId, {
    required String winnerId,
    required int p1Score,
    required int p2Score,
    required String resolutionNotes,
  }) async => const Right(null);

  @override
  Future<Either<Failure, void>> completeTournament(String tournamentId) async => const Right(null);

  @override
  Future<Either<Failure, Map<String, dynamic>>> awardPrizes(String tournamentId) async => const Right({});

  @override
  Future<Either<Failure, List<TournamentAuditLogEntity>>> getAuditLogs(String tournamentId) async => const Right([]);

  @override
  Future<Either<Failure, PaginatedResult<TournamentAuditLogEntity>>> getTournamentAuditLogsPage({
    required String tournamentId,
    int page = 1,
    int pageSize = 50,
  }) async => Right(PaginatedResult.empty(requestedPage: page, requestedPageSize: pageSize));

  @override
  Stream<List<TournamentMatchEntity>> watchDisputedMatches(String tournamentId) => const Stream.empty();
}

void main() {
  late FakeTournamentRepository fakeRepository;
  late FakeLocationService fakeLocationService;
  late FakeStorageService fakeStorageService;
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
    fakeRepository = FakeTournamentRepository();
    fakeLocationService = FakeLocationService();
    fakeStorageService = FakeStorageService();
    cubit = TournamentCubit(fakeRepository, fakeLocationService, fakeStorageService);
  });

  tearDown(() {
    cubit.close();
  });

  test('initial state should be TournamentState()', () {
    expect(cubit.state, equals(const TournamentState()));
  });

  test('loadTournaments emits success state with loaded list', () async {
    fakeRepository.getTournamentsResult = Right([tTournament]);

    await cubit.loadTournaments();

    expect(cubit.state.status, equals(TournamentCubitStatus.success));
    expect(cubit.state.tournaments, equals([tTournament]));
  });

  test('createTournament emits actionSuccess on success', () async {
    fakeRepository.createTournamentResult = Right(tTournament);

    await cubit.createTournament(tTournament);

    expect(cubit.state.status, equals(TournamentCubitStatus.actionSuccess));
    expect(cubit.state.tournaments, contains(tTournament));
  });

  test('deleteDraftTournament handles failure correctly', () async {
    fakeRepository.deleteDraftResult = const Left(ServerFailure('Cannot delete draft with participants'));

    await cubit.deleteDraftTournament('t-1');

    expect(cubit.state.status, equals(TournamentCubitStatus.failure));
    expect(cubit.state.errorMessage, equals('Cannot delete draft with participants'));
  });
}
