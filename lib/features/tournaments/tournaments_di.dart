import 'package:get_it/get_it.dart';
import 'data/datasources/tournament_remote_data_source.dart';
import 'data/repositories/tournament_repository_impl.dart';
import 'domain/repositories/tournament_repository.dart';
import 'presentation/tournament_cubit.dart';

void initTournamentsDI(GetIt sl) {
  // Data Source
  sl.registerLazySingleton<TournamentRemoteDataSource>(
    () => TournamentRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<TournamentRepository>(
    () => TournamentRepositoryImpl(sl()),
  );

  // Cubit
  sl.registerFactory<TournamentCubit>(
    () => TournamentCubit(sl()),
  );
}
