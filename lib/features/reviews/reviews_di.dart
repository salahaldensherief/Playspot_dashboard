import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/datasources/reviews_remote_data_source.dart';
import 'data/repositories/reviews_repository_impl.dart';
import 'domain/repositories/reviews_repository.dart';
import 'domain/usecases/get_lounge_reviews_usecase.dart';
import 'domain/usecases/watch_lounge_reviews_usecase.dart';
import 'presentation/reviews_cubit.dart';

void initReviewsDI(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<ReviewsRemoteDataSource>(
    () => ReviewsRemoteDataSourceImpl(sl<SupabaseClient>()),
  );

  // Repositories
  sl.registerLazySingleton<ReviewsRepository>(
    () => ReviewsRepositoryImpl(sl<ReviewsRemoteDataSource>()),
  );

  // Use Cases
  sl.registerLazySingleton<WatchLoungeReviewsUseCase>(
    () => WatchLoungeReviewsUseCase(sl<ReviewsRepository>()),
  );
  sl.registerLazySingleton<GetLoungeReviewsUseCase>(
    () => GetLoungeReviewsUseCase(sl<ReviewsRepository>()),
  );

  // Cubits
  sl.registerFactory<ReviewsCubit>(
    () => ReviewsCubit(
      watchLoungeReviewsUseCase: sl<WatchLoungeReviewsUseCase>(),
    ),
  );
}
