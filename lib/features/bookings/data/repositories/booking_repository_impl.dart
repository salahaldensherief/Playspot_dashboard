import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/core/utils/paginated_result.dart';
import 'package:play_spot_dashboard/features/bookings/data/datasources/booking_realtime_datasource.dart';
import 'package:play_spot_dashboard/features/bookings/data/datasources/booking_remote_data_source.dart';
import 'package:play_spot_dashboard/features/bookings/data/models/booking_model.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/customer_cancellation_summary.dart';
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
  Future<Either<Failure, PaginatedResult<Booking>>> getLoungeBookingsPage({
    required String loungeId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await remoteDataSource.getLoungeBookingsPage(
        loungeId: loungeId,
        page: page,
        pageSize: pageSize,
      );
      return Right(PaginatedResult<Booking>(
        items: result.items,
        totalCount: result.totalCount,
        page: result.page,
        pageSize: result.pageSize,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustomerCancellationSummary>> getBookingCancellationSummary({
    required String loungeId,
    required String userId,
  }) async {
    try {
      final summary = await remoteDataSource.getBookingCancellationSummary(
        loungeId: loungeId,
        userId: userId,
      );
      return Right(summary);
    } catch (e) {
      return Left(ServerFailure(_mapBookingErrorMessage(e.toString())));
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
      return Left(ServerFailure(_mapBookingErrorMessage(e.message)));
    } catch (e) {
      return Left(ServerFailure(_mapBookingErrorMessage(e.toString())));
    }
  }

  @override
  Future<Either<Failure, void>> approveBooking(String id) async {
    try {
      await remoteDataSource.approveBooking(id);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(_mapBookingErrorMessage(e.message)));
    } catch (e) {
      return Left(ServerFailure(_mapBookingErrorMessage(e.toString())));
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
    } on PostgrestException catch (e) {
      return Left(ServerFailure(_mapBookingErrorMessage(e.message)));
    } catch (e) {
      return Left(ServerFailure(_mapBookingErrorMessage(e.toString())));
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
        voucherCode: booking.voucherCode,
        extras: booking.extras,
        lat: booking.lat,
        lng: booking.lng,
        shiftId: booking.shiftId,
        paymentMethod: booking.paymentMethod,
        senderWalletPhone: booking.senderWalletPhone,
      );
      await remoteDataSource.createBooking(model);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(_mapBookingErrorMessage(e.message)));
    } catch (e) {
      return Left(ServerFailure(_mapBookingErrorMessage(e.toString())));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> validateVoucherByCode(String voucherCode) async {
    try {
      final res = await remoteDataSource.validateVoucherByCode(voucherCode);
      return Right(res);
    } catch (e) {
      return Left(ServerFailure(_mapBookingErrorMessage(e.toString())));
    }
  }

  @override
  Future<Either<Failure, void>> consumeVoucherByCode(String voucherCode, String bookingId) async {
    try {
      await remoteDataSource.consumeVoucherByCode(voucherCode, bookingId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(_mapBookingErrorMessage(e.toString())));
    }
  }

  @override
  Future<Either<Failure, void>> swapRoom(String bookingId, String newRoomId, String actionBy) async {
    try {
      await remoteDataSource.swapRoom(bookingId, newRoomId, actionBy);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(_mapBookingErrorMessage(e.message)));
    } catch (e) {
      return Left(ServerFailure(_mapBookingErrorMessage(e.toString())));
    }
  }

  @override
  Future<Either<Failure, void>> startBookingSession(String bookingId) async {
    try {
      await remoteDataSource.startBookingSession(bookingId);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(_mapBookingErrorMessage(e.message)));
    } catch (e) {
      return Left(ServerFailure(_mapBookingErrorMessage(e.toString())));
    }
  }

  @override
  Future<Either<Failure, void>> autoCancelExpiredBookings() async {
    try {
      await remoteDataSource.autoCancelExpiredBookings();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(_mapBookingErrorMessage(e.toString())));
    }
  }

  @override
  Future<Either<Failure, void>> approveManualBooking(String bookingId, String actionBy) async {
    try {
      await remoteDataSource.approveManualBooking(bookingId, actionBy);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(_mapBookingErrorMessage(e.message)));
    } catch (e) {
      return Left(ServerFailure(_mapBookingErrorMessage(e.toString())));
    }
  }

  @override
  Future<Either<Failure, void>> rejectManualBooking(String bookingId, String reason, String actionBy) async {
    try {
      await remoteDataSource.rejectManualBooking(bookingId, reason, actionBy);
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(_mapBookingErrorMessage(e.message)));
    } catch (e) {
      return Left(ServerFailure(_mapBookingErrorMessage(e.toString())));
    }
  }

  String _mapBookingErrorMessage(String message) {
    final clean = message.toLowerCase();
    if (clean.contains('cash payment is disabled') || clean.contains('cash is disabled')) {
      return 'الدفع الكاش غير متاح في هذه الصالة.';
    }
    if (clean.contains('first booking must use') || clean.contains('first_booking') || clean.contains('first booking')) {
      return 'أول حجز يجب تأكيده بتحويل مسبق.';
    }
    if (clean.contains('sender_wallet_phone is required') || clean.contains('sender_wallet_phone')) {
      return 'يجب إدخال رقم المحفظة الذي تم التحويل منه.';
    }
    if (clean.contains('23p01') || clean.contains('bookings_room_booking_period_excl') || clean.contains('exclusion')) {
      return 'الوقت المحدد تم حجزه بالفعل، يرجى اختيار وقت آخر.';
    }
    return message.replaceFirst('Exception: ', '');
  }
}
