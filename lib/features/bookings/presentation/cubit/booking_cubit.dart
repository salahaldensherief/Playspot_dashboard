import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/audio/audio_service.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/core/utils/realtime_watcher_mixin.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/usecases/confirm_cash_payment.dart';
import '../../domain/usecases/create_booking.dart';
import '../../domain/usecases/start_booking_session.dart';
import '../../domain/usecases/update_booking_status.dart';
import '../../domain/usecases/watch_bookings.dart';
import 'booking_session_scheduler.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingState>
    with RealtimeWatcherMixin<BookingState> {
  final WatchBookings watchBookings;
  final UpdateBookingStatus updateBookingStatus;
  final ConfirmCashPayment confirmCashPaymentUseCase;
  final CreateBooking createBookingUseCase;
  final StartBookingSession startBookingSessionUseCase;
  final BookingRepository repository;
  final AudioService audioService;

  late final BookingSessionScheduler _scheduler;
  final Set<String> _knownBookingIds = {};
  final Set<String> _pendingExtensions = {};
  final Set<String> _pendingActions = {};
  int _scopeVersion = 0;
  int _pageVersion = 0;
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
    if (isClosed) return;
    final cleanLoungeId = (loungeId != null && loungeId.trim().isNotEmpty)
        ? loungeId.trim()
        : null;
    final entityId = cleanLoungeId ?? 'all';

    if (isAlreadyWatching(entityId, forceRefresh: forceRefresh)) {
      return;
    }

    ++_scopeVersion;
    ++_pageVersion;
    _isFirstLoad = true;
    _knownBookingIds.clear();
    _scheduler.resetAlerts();
    _scheduler.start();

    emit(state.copyWith(status: BookingStatusState.loading));

    startWatch<List<Booking>>(
      entityId: entityId,
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
            newlyArrivedBooking = bookings.firstWhere(
              (b) => newIds.contains(b.id),
            );
            AppLogger.debug(
              '🔔 [BOOKING_CUBIT] New booking detected! Playing notification sound...',
            );
            try {
              audioService.playNotificationSound();
            } catch (e) {
              AppLogger.debug('فشل تشغيل صوت التنبيه: $e');
            }
          }
        }

        emit(
          state.copyWith(
            status: BookingStatusState.success,
            bookings: bookings,
            latestNewBooking: newlyArrivedBooking,
          ),
        );
        _scheduler.checkBookingStartTimesAndNotify(bookings);
        _scheduler.checkAndAutoTransitionExpiredSessions(bookings);
      },
      onError: (error) {
        AppLogger.debug('🔴 [BOOKING_CUBIT] watchBookings Error: $error');
        emit(
          state.copyWith(
            status: BookingStatusState.failure,
            errorMessage: error.toString(),
          ),
        );
      },
    );
  }

  Future<void> fetchLoungeBookingsPage({
    required String loungeId,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (isClosed || loungeId.isEmpty) return;
    final requestVersion = ++_pageVersion;
    emit(state.copyWith(status: BookingStatusState.loading));

    final result = await repository.getLoungeBookingsPage(
      loungeId: loungeId,
      page: page,
      pageSize: pageSize,
    );

    if (isClosed || requestVersion != _pageVersion) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: BookingStatusState.failure,
          errorMessage: failure.message.tr(),
        ),
      ),
      (paginated) => emit(
        state.copyWith(
          status: BookingStatusState.success,
          bookings: paginated.items,
          page: paginated.page,
          pageSize: paginated.pageSize,
          totalCount: paginated.totalCount,
        ),
      ),
    );
  }

  Future<bool> createBooking(Booking booking) async {
    if (isClosed) return false;
    emit(state.copyWith(status: BookingStatusState.loading));
    final result = await createBookingUseCase(booking);
    if (isClosed) return false;

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: BookingStatusState.failure,
            errorMessage: failure.message.tr(),
          ),
        );
        return false;
      },
      (_) {
        emit(state.copyWith(status: BookingStatusState.success));
        if (watchedEntityId != null) {
          final targetLoungeId = watchedEntityId == 'all'
              ? null
              : watchedEntityId;
          startWatchingBookings(loungeId: targetLoungeId, forceRefresh: true);
        } else {
          emit(state.copyWith(bookings: [booking, ...state.bookings]));
        }
        return true;
      },
    );
  }

  Future<bool> createManualBooking(Booking booking) async {
    return createBooking(booking);
  }

  Future<bool> _executeBookingAction({
    required String bookingId,
    required Future<Either<Failure, dynamic>> Function() action,
    required String actionName,
  }) async {
    if (isClosed || !_pendingActions.add(bookingId)) return false;
    final scopeVersion = _scopeVersion;
    try {
      final result = await action();
      if (isClosed || scopeVersion != _scopeVersion) return false;
      return result.fold(
        (failure) {
          AppLogger.warning('$actionName failed');
          emit(
            state.copyWith(
              status: BookingStatusState.failure,
              errorMessage: failure.message.tr(),
            ),
          );
          return false;
        },
        (_) {
          emit(state.copyWith(status: BookingStatusState.success));
          return true;
        },
      );
    } finally {
      _pendingActions.remove(bookingId);
    }
  }

  Future<bool> approveBooking(String id) {
    return _executeBookingAction(
      actionName: 'Approve Booking',
      bookingId: id,
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
    return _executeBookingAction(
      actionName: 'Confirm Cash Payment',
      bookingId: bookingId,
      action: () => confirmCashPaymentUseCase(
        bookingId,
        shiftId: shiftId,
        discountAmount: discountAmount,
        discountPercentage: discountPercentage,
        discountReason: discountReason,
      ),
    );
  }

  Future<void> swapRoom(
    String bookingId,
    String newRoomId,
    String actionBy, {
    String? newRoomName,
  }) async {
    await _executeBookingAction(
      bookingId: bookingId,
      actionName: 'Swap Room',
      action: () => repository.swapRoom(bookingId, newRoomId, actionBy),
    );
  }

  Future<bool> startBookingSession(String id) {
    return _executeBookingAction(
      actionName: 'Start Booking Session',
      bookingId: id,
      action: () => startBookingSessionUseCase(id),
    );
  }

  Future<Map<String, dynamic>?> startOpenTimeSession({
    required String roomId,
    String? customerName,
    String? customerPhone,
    String playMode = 'single',
  }) async {
    emit(state.copyWith(status: BookingStatusState.loading));
    final result = await repository.startOpenTimeSession(
      roomId: roomId,
      customerName: customerName,
      customerPhone: customerPhone,
      playMode: playMode,
    );

    if (isClosed) return null;

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: BookingStatusState.failure,
            errorMessage: failure.message.tr(),
          ),
        );
        return null;
      },
      (data) {
        final targetLoungeId = watchedEntityId == 'all'
            ? null
            : watchedEntityId;
        if (watchedEntityId != null) {
          startWatchingBookings(loungeId: targetLoungeId, forceRefresh: true);
        }
        return data;
      },
    );
  }

  Future<Map<String, dynamic>?> completeOpenTimeSession(
    String bookingId,
  ) async {
    final result = await repository.completeOpenTimeSession(bookingId);

    if (isClosed) return null;

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            status: BookingStatusState.failure,
            errorMessage: failure.message.tr(),
          ),
        );
        return null;
      },
      (data) {
        final targetLoungeId = watchedEntityId == 'all'
            ? null
            : watchedEntityId;
        if (watchedEntityId != null) {
          startWatchingBookings(loungeId: targetLoungeId, forceRefresh: true);
        }
        return data;
      },
    );
  }

  Future<bool> markNoShow(String id) {
    return changeBookingStatus(id, BookingStatus.cancelled);
  }

  Future<bool> approveManualBooking(String bookingId, String actionBy) async {
    return _executeBookingAction(
      actionName: 'Approve Manual Booking',
      bookingId: bookingId,
      action: () => repository.approveManualBooking(bookingId, actionBy),
    );
  }

  Future<bool> rejectManualBooking(
    String bookingId,
    String reason,
    String actionBy,
  ) async {
    return _executeBookingAction(
      actionName: 'Reject Manual Booking',
      bookingId: bookingId,
      action: () => repository.rejectManualBooking(bookingId, reason, actionBy),
    );
  }

  Future<bool> changeBookingStatus(String id, BookingStatus newStatus) {
    return _executeBookingAction(
      actionName: 'Change Booking Status',
      bookingId: id,
      action: () => updateBookingStatus(id, newStatus),
    );
  }

  Future<bool> extendBookingDuration(String id, int additionalMinutes) async {
    final foundIndex = state.bookings.indexWhere((b) => b.id == id);
    if (foundIndex == -1 || !_pendingExtensions.add(id)) return false;

    try {
      final result = await repository.extendBookingSession(
        id,
        additionalMinutes,
      );
      if (isClosed) return false;
      return result.fold<bool>(
        (failure) {
          emit(
            state.copyWith(
              status: BookingStatusState.failure,
              errorMessage: failure.message.tr(),
            ),
          );
          return false;
        },
        (_) {
          if (watchedEntityId != null) {
            final targetLoungeId = watchedEntityId == 'all'
                ? null
                : watchedEntityId;
            startWatchingBookings(loungeId: targetLoungeId, forceRefresh: true);
          }
          return true;
        },
      );
    } finally {
      _pendingExtensions.remove(id);
    }
  }

  Future<Map<String, dynamic>?> validateVoucherCode(String code) async {
    if (isClosed) return null;
    final scopeVersion = _scopeVersion;
    final result = await repository.validateVoucherByCode(code);
    if (isClosed || scopeVersion != _scopeVersion) return null;
    return result.fold((failure) {
      emit(state.copyWith(errorMessage: failure.message));
      return null;
    }, (data) => data);
  }

  void updateSelectedDuration(int minutes) {
    if (isClosed) return;
    emit(state.copyWith(selectedDurationMinutes: minutes));
  }

  void clearLatestNewBooking() {
    if (isClosed) return;
    emit(state.copyWith(clearLatestNewBooking: true));
  }

  @override
  Future<void> close() {
    _scheduler.dispose();
    return super.close();
  }
}
