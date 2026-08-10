import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/domain/repositories/booking_repository.dart';
import 'package:play_spot_dashboard/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:play_spot_dashboard/features/bookings/data/datasources/booking_realtime_datasource.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;
  final BookingRealtimeDataSource realtimeDataSource;

  BookingRepositoryImpl(this.remoteDataSource, this.realtimeDataSource);

  @override
  Future<Either<Failure, List<Booking>>> getBookings({
    String? loungeId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final bookings = await remoteDataSource.getBookings(
        loungeId: loungeId,
        status: status,
        limit: limit,
        offset: offset,
      );
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
      await remoteDataSource.updateBookingStatus(id, status.toString().split('.').last);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> confirmCashPayment(String bookingId) async {
    try {
      await remoteDataSource.confirmCashPayment(bookingId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
