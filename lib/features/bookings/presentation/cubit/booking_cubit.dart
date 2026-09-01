import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/audio/audio_service.dart';
import '../../domain/entities/booking.dart';
import '../../domain/usecases/confirm_cash_payment.dart';
import '../../domain/usecases/update_booking_status.dart';
import '../../domain/usecases/watch_bookings.dart';
import '../../domain/usecases/create_booking.dart';
import '../../domain/repositories/booking_repository.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  final WatchBookings watchBookings;
  final UpdateBookingStatus updateBookingStatus;
  final ConfirmCashPayment confirmCashPaymentUseCase;
  final CreateBooking createBookingUseCase;
  final BookingRepository repository;
  final AudioService audioService;
  StreamSubscription? _subscription;
  int _lastBookingCount = 0;

  BookingCubit({
    required this.watchBookings,
    required this.updateBookingStatus,
    required this.confirmCashPaymentUseCase,
    required this.createBookingUseCase,
    required this.repository,
    required this.audioService,
  }) : super(const BookingState());

  void startWatchingBookings({String? loungeId}) {
    if (loungeId == null || loungeId.isEmpty) {
      // For Admins who can see everything, loungeId might be null.
      // But if it's explicitly passed as empty string, we should handle it.
      if (loungeId != null && loungeId.isEmpty) {
         emit(state.copyWith(
          status: BookingStatusState.failure,
          errorMessage: 'Lounge ID is empty',
        ));
        return;
      }
    }
    emit(state.copyWith(status: BookingStatusState.loading));
    _subscription?.cancel();
    _subscription = watchBookings(loungeId: loungeId).listen(
      (bookings) {
        if (isClosed) return;
        if (bookings.length > _lastBookingCount) {
          audioService.playNotificationSound();
        }
        _lastBookingCount = bookings.length;
        emit(state.copyWith(
          status: BookingStatusState.success,
          bookings: bookings,
        ));
      },
      onError: (error) {
        if (isClosed) return;
        emit(state.copyWith(
          status: BookingStatusState.failure,
          errorMessage: error.toString(),
        ));
      },
    );
  }

  Future<void> approveBooking(String id) async {
    final result = await updateBookingStatus(id, BookingStatus.upcoming);
    
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: BookingStatusState.failure,
        errorMessage: failure.message,
      )),
      (_) => null,
    );
  }

  Future<void> rejectBooking(String id) async {
    final result = await updateBookingStatus(id, BookingStatus.cancelled);
    
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: BookingStatusState.failure,
        errorMessage: failure.message,
      )),
      (_) => null,
    );
  }

  Future<void> confirmCashPayment(
    String id, {
    String? shiftId,
    double? discountAmount,
    double? discountPercentage,
    String? discountReason,
  }) async {
    final result = await confirmCashPaymentUseCase(
      id,
      shiftId: shiftId,
      discountAmount: discountAmount,
      discountPercentage: discountPercentage,
      discountReason: discountReason,
    );
    
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: BookingStatusState.failure,
        errorMessage: failure.message,
      )),
      (_) => null,
    );
  }

  Future<void> createManualBooking(Booking booking) async {
    emit(state.copyWith(status: BookingStatusState.loading));
    
    final result = await createBookingUseCase(booking);
    
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: BookingStatusState.failure,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: BookingStatusState.success,
      )),
    );
  }

  Future<void> swapRoom(String bookingId, String newRoomId, String actionBy, {String? newRoomName}) async {
    // Optimistic Update
    final originalBookings = List<Booking>.from(state.bookings);
    final updatedBookings = state.bookings.map((b) {
      if (b.id == bookingId) {
        return b.copyWith(
          roomId: newRoomId,
          roomName: newRoomName ?? b.roomName,
        ); 
      }
      return b;
    }).toList();

    emit(state.copyWith(bookings: updatedBookings.cast<Booking>()));

    final result = await repository.swapRoom(bookingId, newRoomId, actionBy);

    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: BookingStatusState.failure,
        errorMessage: failure.message,
        bookings: originalBookings, // Rollback
      )),
      (_) => null, // Realtime will handle the update
    );
  }

  void updateSelectedDuration(int minutes) {
    emit(state.copyWith(selectedDurationMinutes: minutes));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
