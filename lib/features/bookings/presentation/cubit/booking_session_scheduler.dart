import 'dart:async';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import 'package:play_spot_dashboard/core/audio/audio_service.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/domain/repositories/booking_repository.dart';

/// Handles background timers, automatic session transitions, and audible start-time alerts for bookings.
class BookingSessionScheduler {
  final BookingRepository repository;
  final AudioService audioService;
  final void Function(String bookingId, BookingStatus newStatus)
  onTransitionStatus;

  final DateTime Function() _clock;
  List<Booking> _bookings = const [];
  bool _autoCancelInFlight = false;
  bool _disposed = false;
  Timer? _periodicTimer;
  final Set<String> _alertedStartBookingIds = {};

  BookingSessionScheduler({
    required this.repository,
    required this.audioService,
    required this.onTransitionStatus,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  void start() {
    if (_disposed) return;
    triggerAutoCancelExpired();
    _startPeriodicTimer();
  }

  void resetAlerts() {
    _alertedStartBookingIds.clear();
    _bookings = const [];
  }

  void triggerAutoCancelExpired() {
    if (_disposed || _autoCancelInFlight) return;
    _autoCancelInFlight = true;
    unawaited(
      repository
          .autoCancelExpiredBookings()
          .then((result) {
            result.fold(
              (_) => AppLogger.warning('Expired booking reconciliation failed'),
              (_) =>
                  AppLogger.debug('Expired booking reconciliation completed'),
            );
          })
          .catchError((Object error, StackTrace stack) {
            AppLogger.warning(
              'Expired booking reconciliation unavailable',
              error,
              stack,
            );
          })
          .whenComplete(() => _autoCancelInFlight = false),
    );
  }

  void checkBookingStartTimesAndNotify(List<Booking> bookings) {
    if (_disposed) return;
    _bookings = List<Booking>.unmodifiable(bookings);
    final now = _clock();

    for (final booking in bookings) {
      if (booking.status == BookingStatus.upcoming ||
          booking.status == BookingStatus.pending) {
        final start = booking.startDateTime;
        if (start != null) {
          final diffMinutes = now.difference(start).inMinutes;
          if (!now.isBefore(start) && diffMinutes <= 5) {
            if (!_alertedStartBookingIds.contains(booking.id)) {
              _alertedStartBookingIds.add(booking.id);
              AppLogger.debug(
                '🔔 [BookingSessionScheduler] Booking ${booking.id} start time arrived!',
              );
              try {
                unawaited(
                  audioService.playUrgentAlertSound().catchError(
                    (Object error, StackTrace stack) => AppLogger.warning(
                      'Session start audio unavailable',
                      error,
                      stack,
                    ),
                  ),
                );
              } catch (e) {
                AppLogger.debug('Audio alert error: $e');
              }
            }
          }
        }
      }
    }
  }

  void checkAndAutoTransitionExpiredSessions(List<Booking> bookings) {
    if (_disposed) return;
    final expiredInProgress = bookings.where((b) {
      return b.status == BookingStatus.inProgress &&
          b.isSessionExpired(_clock(), const Duration(minutes: 5));
    }).toList();

    for (final booking in expiredInProgress) {
      AppLogger.debug(
        '🔄 [BookingSessionScheduler] Auto-transitioning expired session ${booking.id} to completed...',
      );
      onTransitionStatus(booking.id, BookingStatus.completed);
    }
  }

  void _startPeriodicTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      triggerAutoCancelExpired();
      checkBookingStartTimesAndNotify(_bookings);
      checkAndAutoTransitionExpiredSessions(_bookings);
    });
  }

  void dispose() {
    _disposed = true;
    _bookings = const [];
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _alertedStartBookingIds.clear();
  }
}
