import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/audio/audio_service.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/core/utils/realtime_watcher_mixin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/usecases/confirm_cash_payment.dart';
import '../../domain/usecases/create_booking.dart';
import '../../domain/usecases/start_booking_session.dart';
import '../../domain/usecases/update_booking_status.dart';
import '../../domain/usecases/watch_bookings.dart';
import 'booking_session_scheduler.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> with RealtimeWatcherMixin<BookingState> {
  final WatchBookings watchBookings;
  final UpdateBookingStatus updateBookingStatus;
  final ConfirmCashPayment confirmCashPaymentUseCase;
  final CreateBooking createBookingUseCase;
  final StartBookingSession startBookingSessionUseCase;
  final BookingRepository repository;
  final AudioService audioService;

  late final BookingSessionScheduler _scheduler;
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
  }) : super(const BookingState()) {
    _scheduler = BookingSessionScheduler(
      repository: repository,
      audioService: audioService,
      onTransitionStatus: (id, status) {
        if (!isClosed) changeBookingStatus(id, status);
      },
    );
  }

  void startWatchingBookings({String? loungeId, bool forceRefresh = false}) {
    final cleanLoungeId = (loungeId != null && loungeId.trim().isNotEmpty) ? loungeId.trim() : null;

    if (isAlreadyWatching(cleanLoungeId, forceRefresh: forceRefresh)) {
      return;
    }

    _isFirstLoad = true;
    _knownBookingIds.clear();
    _scheduler.resetAlerts();
    _scheduler.start();

    emit(state.copyWith(status: BookingStatusState.loading));

    startWatch<List<Booking>>(
      entityId: cleanLoungeId!,
      stream: watchBookings(loungeId: cleanLoungeId),
      onData: (bookings) {
        final currentIds = bookings.map((b) => b.id).toSet();
        Booking? newlyArrivedBooking;

        if (_isFirstLoad) {
          _isFirstLoad = false;
          _knownBookingIds.addAll(currentIds);
        } else {
          final newIds = currentIds.difference(_knownBookingIds);
          if (newIds.isNotEmpty) {
            _knownBookingIds.addAll(newIds);
            newlyArrivedBooking = bookings.firstWhere((b) => newIds.contains(b.id));
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
          latestNewBooking: newlyArrivedBooking,
        ));
        _scheduler.checkBookingStartTimesAndNotify(bookings);
        _scheduler.checkAndAutoTransitionExpiredSessions(bookings);
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

  Future<bool> _executeOptimisticAction({
    required List<Booking> Function(List<Booking> current) optimisticUpdate,
    required Future<Either<Failure, dynamic>> Function() action,
    required String actionName,
  }) async {
    final originalBookings = List<Booking>.from(state.bookings);
    final updated = optimisticUpdate(state.bookings);
    emit(state.copyWith(bookings: updated));

    final result = await action();
    if (isClosed) return false;

    return result.fold(
      (failure) {
        debugPrint('🔴 [CUBIT] $actionName Failed: ${failure.message}');
        emit(state.copyWith(
          status: BookingStatusState.failure,
          errorMessage: failure.message,
          bookings: originalBookings,
        ));
        return false;
      },
      (_) {
        debugPrint('🟢 [CUBIT] $actionName Succeeded');
        if (watchedEntityId != null) {
          startWatchingBookings(loungeId: watchedEntityId);
        }
        return true;
      },
    );
  }

  Future<bool> approveBooking(String id) {
    return _executeOptimisticAction(
      actionName: 'Approve Booking',
      optimisticUpdate: (list) => list
          .map((b) => b.id == id
              ? b.copyWith(status: BookingStatus.upcoming, paymentStatus: PaymentStatus.paid)
              : b)
          .toList(),
      action: () => repository.approveBooking(id),
    );
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
  }) {
    return _executeOptimisticAction(
      actionName: 'Confirm Cash Payment',
      optimisticUpdate: (list) => list
          .map((b) => b.id == bookingId
              ? b.copyWith(status: BookingStatus.completed, paymentStatus: PaymentStatus.paid)
              : b)
          .toList(),
      action: () => confirmCashPaymentUseCase(
        bookingId,
        shiftId: shiftId,
        discountAmount: discountAmount,
        discountPercentage: discountPercentage,
        discountReason: discountReason,
      ),
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
        bookings: originalBookings,
      )),
      (_) => null,
    );
  }

  Future<bool> startBookingSession(String id) {
    return _executeOptimisticAction(
      actionName: 'Start Booking Session',
      optimisticUpdate: (list) =>
          list.map((b) => b.id == id ? b.copyWith(status: BookingStatus.inProgress) : b).toList(),
      action: () => startBookingSessionUseCase(id),
    );
  }

  Future<bool> markNoShow(String id) {
    return changeBookingStatus(id, BookingStatus.cancelled);
  }

  Future<bool> changeBookingStatus(String id, BookingStatus newStatus) {
    return _executeOptimisticAction(
      actionName: 'Change Booking Status',
      optimisticUpdate: (list) =>
          list.map((b) => b.id == id ? b.copyWith(status: newStatus) : b).toList(),
      action: () => updateBookingStatus(id, newStatus),
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

  void clearLatestNewBooking() {
    emit(state.copyWith(clearLatestNewBooking: true));
  }

  @override
  Future<void> close() {
    _scheduler.dispose();
    return super.close();
  }
}
