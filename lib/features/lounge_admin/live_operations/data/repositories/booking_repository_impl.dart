import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/lounge_admin/live_operations/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/lounge_admin/live_operations/domain/repositories/booking_repository.dart';
import 'package:play_spot_dashboard/features/lounge_admin/live_operations/data/datasources/booking_remote_data_source.dart';
import 'package:play_spot_dashboard/features/lounge_admin/live_operations/data/datasources/booking_realtime_datasource.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;
  final BookingRealtimeDataSource realtimeDataSource;

  BookingRepositoryImpl(this.remoteDataSource, this.realtimeDataSource);

  @override
  Future<Either<Failure, List<Booking>>> getBookings({String? loungeId}) async {
    try {
      final bookings = await remoteDataSource.getBookings(loungeId: loungeId);
      return Right(bookings);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<Booking>> watchBookings({String? loungeId}) {
    return realtimeDataSource.watchBookings(loungeId: loungeId);
  }

  @override
  Future<Either<Failure, void>> updateBookingStatus(String id, BookingStatus status) async {
    try {
      await remoteDataSource.updateBookingStatus(id, status.name);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
