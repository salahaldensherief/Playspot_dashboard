import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/audio/audio_service.dart';
import '../../domain/entities/booking.dart';
import '../../domain/usecases/confirm_cash_payment.dart';
import '../../domain/usecases/update_booking_status.dart';
import '../../domain/usecases/watch_bookings.dart';
import '../../domain/usecases/create_booking.dart';
import '../../domain/usecases/start_booking_session.dart';
import '../../domain/repositories/booking_repository.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  final WatchBookings watchBookings;
  final UpdateBookingStatus updateBookingStatus;
  final ConfirmCashPayment confirmCashPaymentUseCase;
  final CreateBooking createBookingUseCase;
  final StartBookingSession startBookingSessionUseCase;
  final BookingRepository repository;
  final AudioService audioService;
  StreamSubscription? _subscription;
  Timer? _autoCancelTimer;
  
  final Set<String> _knownBookingIds = {};
  bool _isFirstLoad = true;
  String? _watchedLoungeId;

  BookingCubit({
    required this.watchBookings,
    required this.updateBookingStatus,
    required this.confirmCashPaymentUseCase,
    required this.createBookingUseCase,
    required this.startBookingSessionUseCase,
    required this.repository,
    required this.audioService,
  }) : super(const BookingState());

  void startWatchingBookings({String? loungeId}) {
    final cleanLoungeId = (loungeId != null && loungeId.trim().isNotEmpty) ? loungeId.trim() : null;

    // Avoid re-subscribing only if active subscription exists AND loungeId hasn't changed
    if (_subscription != null && _watchedLoungeId == cleanLoungeId) {
      return;
    }

    _watchedLoungeId = cleanLoungeId;
    _isFirstLoad = true;
    _knownBookingIds.clear();

    // Trigger auto-cancel for overdue bookings on startup & start periodic background check
    _triggerAutoCancelExpired();
    _startPeriodicAutoCancelTimer();

    emit(state.copyWith(status: BookingStatusState.loading));
    _subscription?.cancel();

    _subscription = watchBookings(loungeId: cleanLoungeId).listen(
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
            debugPrint('🔔 [BOOKING_CUBIT] New booking detected! Playing notification sound...');
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
        debugPrint('🔴 [BOOKING_CUBIT] watchBookings Error: $error');
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

  Future<bool> startBookingSession(String id) async {
    // 1. Optimistic UI update to reflect in_progress status immediately
    final originalBookings = List<Booking>.from(state.bookings);
    final updatedList = state.bookings.map((b) {
      if (b.id == id) return b.copyWith(status: BookingStatus.inProgress);
      return b;
    }).toList();
    emit(state.copyWith(bookings: updatedList));

    // 2. Call RPC via usecase
    final result = await startBookingSessionUseCase(id);
    if (isClosed) return false;

    return result.fold(
      (failure) {
        debugPrint('🔴 [CUBIT] Start Booking Session Failed: ${failure.message}');
        emit(state.copyWith(
          status: BookingStatusState.failure,
          errorMessage: failure.message,
          bookings: originalBookings,
        ));
        return false;
      },
      (_) {
        debugPrint('🟢 [CUBIT] Start Booking Session Succeeded in Supabase');
        if (_watchedLoungeId != null) {
          startWatchingBookings(loungeId: _watchedLoungeId);
        }
        return true;
      },
    );
  }

  Future<bool> markNoShow(String id) async {
    // 1. Optimistic UI update to cancel booking immediately and release room
    final originalBookings = List<Booking>.from(state.bookings);
    final updatedList = state.bookings.map((b) {
      if (b.id == id) return b.copyWith(status: BookingStatus.cancelled);
      return b;
    }).toList();
    emit(state.copyWith(bookings: updatedList));

    // 2. Send cancellation to server
    final result = await updateBookingStatus(id, BookingStatus.cancelled);
    if (isClosed) return false;

    return result.fold(
      (failure) {
        debugPrint('🔴 [CUBIT] Mark No-Show Failed: ${failure.message}');
        emit(state.copyWith(
          status: BookingStatusState.failure,
          errorMessage: failure.message,
          bookings: originalBookings,
        ));
        return false;
      },
      (_) {
        debugPrint('🟢 [CUBIT] Mark No-Show Succeeded in Supabase');
        if (_watchedLoungeId != null) {
          startWatchingBookings(loungeId: _watchedLoungeId);
        }
        return true;
      },
    );
  }

  Future<bool> changeBookingStatus(String id, BookingStatus newStatus) async {
    // 1. Optimistic UI update to reflect the new status immediately
    final originalBookings = List<Booking>.from(state.bookings);
    final updatedList = state.bookings.map((b) {
      if (b.id == id) return b.copyWith(status: newStatus);
      return b;
    }).toList();
    emit(state.copyWith(bookings: updatedList));

    // 2. Send update to server
    final result = await updateBookingStatus(id, newStatus);
    if (isClosed) return false;

    return result.fold(
      (failure) {
        debugPrint('🔴 [CUBIT] Change Booking Status Failed: ${failure.message}');
        emit(state.copyWith(
          status: BookingStatusState.failure,
          errorMessage: failure.message,
          bookings: originalBookings,
        ));
        return false;
      },
      (_) {
        debugPrint('🟢 [CUBIT] Change Booking Status Succeeded in Supabase');
        if (_watchedLoungeId != null) {
          startWatchingBookings(loungeId: _watchedLoungeId);
        }
        return true;
      },
    );
  }

  Future<bool> extendBookingDuration(String id, int additionalMinutes) async {
    final originalBookings = List<Booking>.from(state.bookings);
    final foundIndex = state.bookings.indexWhere((b) => b.id == id);
    if (foundIndex == -1) return false;

    final booking = state.bookings[foundIndex];
    final newDuration = booking.durationMinutes + additionalMinutes;

    final updatedList = state.bookings.map((b) {
      if (b.id == id) return b.copyWith(durationMinutes: newDuration);
      return b;
    }).toList();
    emit(state.copyWith(bookings: updatedList));

    try {
      await repository.createBooking(booking.copyWith(durationMinutes: newDuration));
      if (_watchedLoungeId != null) {
        startWatchingBookings(loungeId: _watchedLoungeId);
      }
      return true;
    } catch (e) {
      debugPrint('🔴 [CUBIT] Extend Duration Failed: $e');
      emit(state.copyWith(
        status: BookingStatusState.failure,
        errorMessage: e.toString(),
        bookings: originalBookings,
      ));
      return false;
    }
  }

  void updateSelectedDuration(int minutes) {
    emit(state.copyWith(selectedDurationMinutes: minutes));
  }

  void _triggerAutoCancelExpired() {
    repository.autoCancelExpiredBookings().then((_) {
      debugPrint('🟢 [BookingCubit] autoCancelExpiredBookings completed');
    }).catchError((e) {
      debugPrint('⚠️ [BookingCubit] autoCancelExpiredBookings error: $e');
    });
  }

  void _startPeriodicAutoCancelTimer() {
    _autoCancelTimer?.cancel();
    _autoCancelTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!isClosed) {
        _triggerAutoCancelExpired();
      }
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _autoCancelTimer?.cancel();
    return super.close();
  }
}
