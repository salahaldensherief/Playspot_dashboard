import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/bookings/data/datasources/booking_realtime_datasource.dart';
import 'package:play_spot_dashboard/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:play_spot_dashboard/features/bookings/data/models/booking_model.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/domain/repositories/booking_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      await remoteDataSource.updateBookingStatus(id, status.toDbString());
      return const Right(null);
    } on PostgrestException catch (e) {
      if (e.code == '23P01') {
        return const Left(ServerFailure('الوقت المحدد تم حجزه بالفعل، يرجى اختيار وقت آخر'));
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> confirmCashPayment(
    String bookingId, {
    String? shiftId,
    double? discountAmount,
    double? discountPercentage,
    String? discountReason,
  }) async {
    try {
      await remoteDataSource.confirmCashPayment(
        bookingId,
        shiftId: shiftId,
        discountAmount: discountAmount,
        discountPercentage: discountPercentage,
        discountReason: discountReason,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createBooking(Booking booking) async {
    try {
      final model = BookingModel(
        id: booking.id,
        userId: booking.userId,
        userName: booking.userName,
        userEmail: booking.userEmail,
        userPhone: booking.userPhone,
        loungeId: booking.loungeId,
        roomId: booking.roomId,
        loungeName: booking.loungeName,
        loungeLocation: booking.loungeLocation,
        roomName: booking.roomName,
        controllersCount: booking.controllersCount,
        screenSize: booking.screenSize,
        date: booking.date,
        startTime: booking.startTime,
        endTime: booking.endTime,
        status: booking.status,
        paymentStatus: booking.paymentStatus,
        totalPrice: booking.totalPrice,
        voucherDiscount: booking.voucherDiscount,
        extras: booking.extras,
        lat: booking.lat,
        lng: booking.lng,
        shiftId: booking.shiftId,
      );
      await remoteDataSource.createBooking(model);
      return const Right(null);
    } on PostgrestException catch (e) {
      if (e.code == '23P01') {
        return const Left(ServerFailure('الوقت المحدد تم حجزه بالفعل، يرجى اختيار وقت آخر'));
      }
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> swapRoom(String bookingId, String newRoomId, String actionBy) async {
    try {
      await remoteDataSource.swapRoom(bookingId, newRoomId, actionBy);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> startBookingSession(String bookingId) async {
    try {
      await remoteDataSource.startBookingSession(bookingId);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> autoCancelExpiredBookings() async {
    try {
      await remoteDataSource.autoCancelExpiredBookings();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
