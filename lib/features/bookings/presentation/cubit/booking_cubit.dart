import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/utils/realtime_watcher_mixin.dart';
import '../../../../core/audio/audio_service.dart';
import '../../domain/entities/booking.dart';
import '../../domain/usecases/confirm_cash_payment.dart';
import '../../domain/usecases/update_booking_status.dart';
import '../../domain/usecases/watch_bookings.dart';
import '../../domain/usecases/create_booking.dart';
import '../../domain/usecases/start_booking_session.dart';
import '../../domain/repositories/booking_repository.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> with RealtimeWatcherMixin<BookingState> {
  final WatchBookings watchBookings;
  final UpdateBookingStatus updateBookingStatus;
  final ConfirmCashPayment confirmCashPaymentUseCase;
  final CreateBooking createBookingUseCase;
  final StartBookingSession startBookingSessionUseCase;
  final BookingRepository repository;
  final AudioService audioService;
  Timer? _autoCancelTimer;
  
  final Set<String> _knownBookingIds = {};
  bool _isFirstLoad = true;

  BookingCubit({
    required this.watchBookings,
    required this.updateBookingStatus,
    required this.confirmCashPaymentUseCase,
    required this.createBookingUseCase,
    required this.startBookingSessionUseCase,
    required this.repository,
    required this.audioService,
  }) : super(const BookingState());

  void startWatchingBookings({String? loungeId, bool forceRefresh = false}) {
    final cleanLoungeId = (loungeId != null && loungeId.trim().isNotEmpty) ? loungeId.trim() : null;

    if (isAlreadyWatching(cleanLoungeId, forceRefresh: forceRefresh)) {
      return;
    }

    _isFirstLoad = true;
    _knownBookingIds.clear();

    // Trigger auto-cancel for overdue bookings on startup & start periodic background check
    _triggerAutoCancelExpired();
    _startPeriodicAutoCancelTimer();

    emit(state.copyWith(status: BookingStatusState.loading));

    startWatch<List<Booking>>(
      entityId: cleanLoungeId!,
      stream: watchBookings(loungeId: cleanLoungeId),
      onData: (bookings) {
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
        _checkAndAutoTransitionExpiredSessions();
      },
      onError: (error) {
        debugPrint('🔴 [BOOKING_CUBIT] watchBookings Error: $error');
        emit(state.copyWith(
          status: BookingStatusState.failure,
          errorMessage: error.toString(),
        ));
      },
    );
  }

  Future<void> fetchLoungeBookingsPage({
    required String loungeId,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (loungeId.isEmpty) return;
    emit(state.copyWith(status: BookingStatusState.loading));

    final result = await repository.getLoungeBookingsPage(
      loungeId: loungeId,
      page: page,
      pageSize: pageSize,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: BookingStatusState.failure,
        errorMessage: failure.message,
      )),
      (paginated) => emit(state.copyWith(
        status: BookingStatusState.success,
        bookings: paginated.items,
        page: paginated.page,
        pageSize: paginated.pageSize,
        totalCount: paginated.totalCount,
      )),
    );
  }

  Future<bool> createBooking(Booking booking) async {
    emit(state.copyWith(status: BookingStatusState.loading));
    final result = await createBookingUseCase(booking);
    if (isClosed) return false;

    return result.fold(
      (failure) {
        emit(state.copyWith(
          status: BookingStatusState.failure,
          errorMessage: failure.message,
        ));
        return false;
      },
      (_) {
        emit(state.copyWith(
          status: BookingStatusState.success,
          bookings: [booking, ...state.bookings],
        ));
        return true;
      },
    );
  }

  Future<bool> createManualBooking(Booking booking) async {
    return createBooking(booking);
  }

  Future<bool> approveBooking(String id) async {
    return changeBookingStatus(id, BookingStatus.upcoming);
  }

  Future<bool> rejectBooking(String id) async {
    return changeBookingStatus(id, BookingStatus.cancelled);
  }

  Future<bool> confirmCashPayment(
    String bookingId, {
    String? shiftId,
    double? discountAmount,
    double? discountPercentage,
    String? discountReason,
    double? amount,
    String? actionBy,
  }) async {
    // 1. Optimistic UI update to mark as confirmed & paid
    final originalBookings = List<Booking>.from(state.bookings);
    final updatedBookings = state.bookings.map((b) {
      if (b.id == bookingId) {
        return b.copyWith(
          status: BookingStatus.completed,
          paymentStatus: PaymentStatus.paid,
        );
      }
      return b;
    }).toList();

    emit(state.copyWith(bookings: updatedBookings));

    // 2. Call backend
    final result = await confirmCashPaymentUseCase(
      bookingId,
      shiftId: shiftId,
      discountAmount: discountAmount,
      discountPercentage: discountPercentage,
      discountReason: discountReason,
    );

    if (isClosed) return false;

    return result.fold(
      (failure) {
        debugPrint('🔴 [CUBIT] Confirm Cash Payment Failed: ${failure.message}');
        emit(state.copyWith(
          status: BookingStatusState.failure,
          errorMessage: failure.message,
          bookings: originalBookings, // Rollback
        ));
        return false;
      },
      (_) {
        debugPrint('🟢 [CUBIT] Confirm Cash Payment Succeeded in Supabase');
        if (watchedEntityId != null) {
          startWatchingBookings(loungeId: watchedEntityId);
        }
        return true;
      },
    );
  }

  Future<void> swapRoom(String bookingId, String newRoomId, String actionBy, {String? newRoomName}) async {
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
        if (watchedEntityId != null) {
          startWatchingBookings(loungeId: watchedEntityId);
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
        if (watchedEntityId != null) {
          startWatchingBookings(loungeId: watchedEntityId);
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
        if (watchedEntityId != null) {
          startWatchingBookings(loungeId: watchedEntityId);
        }
        return true;
      },
    );
  }

  Future<bool> extendBookingDuration(String id, int additionalMinutes) async {
    final originalBookings = List<Booking>.from(state.bookings);
    final foundIndex = state.bookings.indexWhere((b) => b.id == id);
    if (foundIndex == -1) return false;

    try {
      final client = Supabase.instance.client;
      await client.rpc('extend_booking_session', params: {
        'p_booking_id': id,
        'p_additional_minutes': additionalMinutes,
      });

      if (watchedEntityId != null) {
        startWatchingBookings(loungeId: watchedEntityId);
      }
      return true;
    } catch (e) {
      final errorStr = e.toString();
      debugPrint('🔴 [CUBIT] Extend Duration Failed: $errorStr');
      final cleanMessage = errorStr.contains('BOOKING_EXTENSION_CONFLICT')
          ? 'لا يمكن تمديد الحجز لأن هناك حجزاً آخر يبدأ بعد وقت حجزك مباشرة.'
          : errorStr.replaceFirst('Exception: ', '');

      emit(state.copyWith(
        status: BookingStatusState.failure,
        errorMessage: cleanMessage,
        bookings: originalBookings,
      ));
      return false;
    }
  }

  Future<Map<String, dynamic>?> validateVoucherCode(String code) async {
    final result = await repository.validateVoucherByCode(code);
    return result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
        return null;
      },
      (data) => data,
    );
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

  void _checkAndAutoTransitionExpiredSessions() {
    if (isClosed) return;
    final expiredInProgress = state.bookings.where((b) {
      // 5-minute grace period matching the mobile client's getActiveSession logic
      return b.status == BookingStatus.inProgress && b.isSessionExpired(null, const Duration(minutes: 5));
    }).toList();

    for (final booking in expiredInProgress) {
      debugPrint('🔄 [BOOKING_CUBIT] Auto-transitioning expired session ${booking.id} to completed...');
      changeBookingStatus(booking.id, BookingStatus.completed);
    }
  }

  void _startPeriodicAutoCancelTimer() {
    _autoCancelTimer?.cancel();
    // Reduced polling frequency to 5 minutes to prevent unnecessary DB hits.
    // Recommended: Use Supabase pg_cron for server-side auto-cancel.
    _autoCancelTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (!isClosed) {
        _triggerAutoCancelExpired();
        _checkAndAutoTransitionExpiredSessions();
      }
    });
  }

  @override
  Future<void> close() {
    _autoCancelTimer?.cancel();
    return super.close();
  }
}
