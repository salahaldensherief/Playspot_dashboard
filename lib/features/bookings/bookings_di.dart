import 'package:get_it/get_it.dart';
import 'data/datasources/booking_remote_data_source.dart';
import 'data/datasources/booking_realtime_datasource.dart';
import 'data/repositories/booking_repository_impl.dart';
import 'domain/repositories/booking_repository.dart';
import 'domain/usecases/watch_bookings.dart';
import 'domain/usecases/update_booking_status.dart';
import 'domain/usecases/confirm_cash_payment.dart';
import 'domain/usecases/create_booking.dart';
import 'presentation/cubit/booking_cubit.dart';

void initBookingsDI(GetIt sl) {
  // Data Sources
  sl.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<BookingRealtimeDataSource>(
    () => BookingRealtimeDataSourceImpl(sl(), sl()),
  );

  // Repositories
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(sl(), sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => WatchBookings(sl()));
  sl.registerLazySingleton(() => UpdateBookingStatus(sl()));
  sl.registerLazySingleton(() => ConfirmCashPayment(sl()));
  sl.registerLazySingleton(() => CreateBooking(sl()));

  // Cubits
  sl.registerFactory<BookingCubit>(
    () => BookingCubit(
      watchBookings: sl(),
      updateBookingStatus: sl(),
      confirmCashPaymentUseCase: sl(),
      createBookingUseCase: sl(),
      repository: sl(),
      audioService: sl(),
    ),
  );
}
