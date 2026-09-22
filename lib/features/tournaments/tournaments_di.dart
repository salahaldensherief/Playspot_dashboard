import 'package:get_it/get_it.dart';
import 'data/datasources/tournament_remote_data_source.dart';
import 'data/repositories/tournament_repository_impl.dart';
import 'domain/repositories/tournament_repository.dart';
import 'domain/usecases/tournament_match_usecases.dart';
import 'domain/usecases/tournament_participant_usecases.dart';
import 'domain/usecases/tournament_usecases.dart';
import 'presentation/tournament_cubit.dart';
import 'presentation/tournament_matches_cubit.dart';
import 'presentation/tournament_participants_cubit.dart';

void initTournamentsDI(GetIt sl) {
  // Data Source
  sl.registerLazySingleton<TournamentRemoteDataSource>(
    () => TournamentRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<TournamentRepository>(
    () => TournamentRepositoryImpl(sl()),
  );

  // Tournament Lifecycle Use Cases
  sl.registerLazySingleton(() => GetTournamentsUseCase(sl()));
  sl.registerLazySingleton(() => CreateTournamentUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTournamentUseCase(sl()));
  sl.registerLazySingleton(() => SaveTournamentPrizesUseCase(sl()));
  sl.registerLazySingleton(() => PublishTournamentUseCase(sl()));
  sl.registerLazySingleton(() => CancelTournamentUseCase(sl()));
  sl.registerLazySingleton(() => DeleteDraftTournamentUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTournamentUseCase(sl()));
  sl.registerLazySingleton(() => CompleteTournamentUseCase(sl()));
  sl.registerLazySingleton(() => AwardPrizesUseCase(sl()));
  sl.registerLazySingleton(() => GetTournamentAuditLogsUseCase(sl()));
  sl.registerLazySingleton(() => WatchDisputedMatchesUseCase(sl()));

  // Participant Use Cases
  sl.registerLazySingleton(() => GetTournamentParticipantsUseCase(sl()));
  sl.registerLazySingleton(() => ApproveParticipantPaymentUseCase(sl()));
  sl.registerLazySingleton(() => RejectParticipantPaymentUseCase(sl()));
  sl.registerLazySingleton(() => RecordCashPaymentUseCase(sl()));
  sl.registerLazySingleton(() => PromoteWaitlistUseCase(sl()));
  sl.registerLazySingleton(() => CheckInParticipantUseCase(sl()));
  sl.registerLazySingleton(() => WithdrawParticipantUseCase(sl()));

  // Match Use Cases
  sl.registerLazySingleton(() => GetTournamentMatchesUseCase(sl()));
  sl.registerLazySingleton(() => DrawBracketUseCase(sl()));
  sl.registerLazySingleton(() => StartMatchUseCase(sl()));
  sl.registerLazySingleton(() => ResolveDisputeUseCase(sl()));

  // Cubits
  sl.registerFactory<TournamentCubit>(
    () => TournamentCubit(
      getTournamentsUseCase: sl(),
      createTournamentUseCase: sl(),
      updateTournamentUseCase: sl(),
      saveTournamentPrizesUseCase: sl(),
      publishTournamentUseCase: sl(),
      cancelTournamentUseCase: sl(),
      deleteDraftTournamentUseCase: sl(),
      deleteTournamentUseCase: sl(),
      completeTournamentUseCase: sl(),
      awardPrizesUseCase: sl(),
      getTournamentAuditLogsUseCase: sl(),
      watchDisputedMatchesUseCase: sl(),
      getParticipantsUseCase: sl(),
      approvePaymentUseCase: sl(),
      rejectPaymentUseCase: sl(),
      recordCashPaymentUseCase: sl(),
      promoteWaitlistUseCase: sl(),
      checkInParticipantUseCase: sl(),
      withdrawParticipantUseCase: sl(),
      drawBracketUseCase: sl(),
      getMatchesUseCase: sl(),
      startMatchUseCase: sl(),
      resolveDisputeUseCase: sl(),
      locationService: sl(),
      storageService: sl(),
    ),
  );

  sl.registerFactory<TournamentParticipantsCubit>(
    () => TournamentParticipantsCubit(
      getParticipantsUseCase: sl(),
      approvePaymentUseCase: sl(),
      rejectPaymentUseCase: sl(),
      recordCashPaymentUseCase: sl(),
      promoteWaitlistUseCase: sl(),
      checkInParticipantUseCase: sl(),
      withdrawParticipantUseCase: sl(),
    ),
  );

  sl.registerFactory<TournamentMatchesCubit>(
    () => TournamentMatchesCubit(
      getMatchesUseCase: sl(),
      drawBracketUseCase: sl(),
      startMatchUseCase: sl(),
      resolveDisputeUseCase: sl(),
      watchDisputedMatchesUseCase: sl(),
    ),
  );
}
