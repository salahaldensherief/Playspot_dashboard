import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/domain/usecases/watch_bookings.dart';
import 'package:play_spot_dashboard/features/bookings/domain/usecases/update_booking_status.dart';
import 'package:play_spot_dashboard/core/audio/audio_service.dart';
import 'package:play_spot_dashboard/core/di/di.dart';

part 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  final WatchBookings watchBookings;
  final UpdateBookingStatus updateBookingStatus;
  final AudioService audioService = sl<AudioService>();
  StreamSubscription? _subscription;
  int _lastBookingCount = 0;

  BookingCubit({
    required this.watchBookings,
    required this.updateBookingStatus,
  }) : super(BookingInitial());

  void startWatchingBookings({String? loungeId}) {
    emit(BookingLoading());
    _subscription?.cancel();
    _subscription = watchBookings(loungeId: loungeId).listen(
      (bookings) {
        // Trigger sound if new booking arrived
        if (bookings.length > _lastBookingCount) {
          audioService.playNotificationSound();
        }
        _lastBookingCount = bookings.length;
        emit(BookingLoaded(bookings));
      },
      onError: (error) {
        emit(BookingError(error.toString()));
      },
    );
  }

  Future<void> confirmCashPayment(String id) async {
    // Business rule: Confirm payment and complete booking
    final result = await updateBookingStatus(id, BookingStatus.completed);
    result.fold(
      (failure) => emit(BookingError(failure.message)),
      (_) => null,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
