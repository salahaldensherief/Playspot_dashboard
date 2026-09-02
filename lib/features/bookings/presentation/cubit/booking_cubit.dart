import 'dart:async';
import 'package:flutter/material.dart';
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
  
  final Set<String> _knownBookingIds = {};
  bool _isFirstLoad = true;
  String? _watchedLoungeId;

  BookingCubit({
    required this.watchBookings,
    required this.updateBookingStatus,
    required this.confirmCashPaymentUseCase,
    required this.createBookingUseCase,
    required this.repository,
    required this.audioService,
  }) : super(const BookingState());

  void startWatchingBookings({String? loungeId}) {
    if (loungeId != null && loungeId.isEmpty) {
      emit(state.copyWith(
        status: BookingStatusState.failure,
        errorMessage: 'Lounge ID is empty',
      ));
      return;
    }

    // تجنب إعادة الاشتراك إذا كان يتتبع بالفعل نفس الـ loungeId
    if (_subscription != null && _watchedLoungeId == loungeId) {
      return;
    }

    _watchedLoungeId = loungeId;
    _isFirstLoad = true;
    _knownBookingIds.clear();

    emit(state.copyWith(status: BookingStatusState.loading));
    _subscription?.cancel();

    _subscription = watchBookings(loungeId: loungeId).listen(
      (bookings) {
        if (isClosed) return;

        final currentIds = bookings.map((b) => b.id).toSet();

        if (_isFirstLoad) {
          _isFirstLoad = false;
          _knownBookingIds.addAll(currentIds);
        } else {
          final newIds = currentIds.difference(_knownBookingIds);
          if (newIds.isNotEmpty) {
            _knownBookingIds.addAll(newIds);
            try {
              audioService.playNotificationSound();
            } catch (e) {
              debugPrint('فشل تشغيل صوت التنبيه: $e');
            }
          }
        }

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
    // 1. تحديث فوري وسريع للواجهة (Optimistic UI)
    final updatedList = state.bookings.map((b) {
      if (b.id == id) return b.copyWith(status: BookingStatus.upcoming);
      return b;
    }).toList();
    emit(state.copyWith(bookings: updatedList));

    // 2. إرسال التحديث للسيرفر
    final result = await updateBookingStatus(id, BookingStatus.upcoming);
    if (isClosed) return;

    result.fold(
          (failure) {
        debugPrint('🔴 [CUBIT] Approve Failed: ${failure.message}');
        emit(state.copyWith(
          status: BookingStatusState.failure,
          errorMessage: failure.message,
        ));
      },
          (_) => debugPrint('🟢 [CUBIT] Approve Succeeded in Supabase'),
    );
  }

  Future<void> rejectBooking(String id) async {
    // 1. تحديث فوري وسريع للواجهة (Optimistic UI)
    final updatedList = state.bookings.map((b) {
      if (b.id == id) return b.copyWith(status: BookingStatus.cancelled);
      return b;
    }).toList();
    emit(state.copyWith(bookings: updatedList));

    // 2. إرسال التحديث للسيرفر
    final result = await updateBookingStatus(id, BookingStatus.cancelled);
    if (isClosed) return;

    result.fold(
          (failure) {
        debugPrint('🔴 [CUBIT] Reject Failed: ${failure.message}');
        emit(state.copyWith(
          status: BookingStatusState.failure,
          errorMessage: failure.message,
        ));
      },
          (_) => debugPrint('🟢 [CUBIT] Reject Succeeded in Supabase'),
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
          (_) {
        final updatedBookings = state.bookings.map((booking) {
          if (booking.id == id) {
            return booking.copyWith(
              paymentStatus: PaymentStatus.paid,
            );
          }
          return booking;
        }).toList();

        emit(state.copyWith(
          status: BookingStatusState.success,
          bookings: updatedBookings,
        ));
      },
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
