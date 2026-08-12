import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/booking.dart';
import '../../domain/usecases/watch_bookings.dart';
import '../../domain/usecases/update_booking_status.dart';
import '../../domain/usecases/confirm_cash_payment.dart';
import '../../../../core/audio/audio_service.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  final WatchBookings watchBookings;
  final UpdateBookingStatus updateBookingStatus;
  final ConfirmCashPayment confirmCashPaymentUseCase;
  final AudioService audioService;
  StreamSubscription? _subscription;
  int _lastBookingCount = 0;

  BookingCubit({
    required this.watchBookings,
    required this.updateBookingStatus,
    required this.confirmCashPaymentUseCase,
    required this.audioService,
  }) : super(const BookingState());

  void startWatchingBookings({String? loungeId}) {
    emit(state.copyWith(status: BookingStatusState.loading));
    _subscription?.cancel();
    _subscription = watchBookings(loungeId: loungeId).listen(
      (bookings) {
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
        emit(state.copyWith(
          status: BookingStatusState.failure,
          errorMessage: error.toString(),
        ));
      },
    );
  }

  Future<void> approveBooking(String id) async {
    final result = await updateBookingStatus(id, BookingStatus.upcoming);
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
    result.fold(
      (failure) => emit(state.copyWith(
        status: BookingStatusState.failure,
        errorMessage: failure.message,
      )),
      (_) => null,
    );
  }

  Future<void> confirmCashPayment(String id) async {
    final result = await confirmCashPaymentUseCase(id);
    result.fold(
      (failure) => emit(state.copyWith(
        status: BookingStatusState.failure,
        errorMessage: failure.message,
      )),
      (_) => null,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
