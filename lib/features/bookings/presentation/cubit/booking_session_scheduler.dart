import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:play_spot_dashboard/core/audio/audio_service.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:play_spot_dashboard/features/bookings/domain/repositories/booking_repository.dart';

/// Handles background timers, automatic session transitions, and audible start-time alerts for bookings.
class BookingSessionScheduler {
  final BookingRepository repository;
  final AudioService audioService;
  final void Function(String bookingId, BookingStatus newStatus) onTransitionStatus;

  Timer? _periodicTimer;
  final Set<String> _alertedStartBookingIds = {};

  BookingSessionScheduler({
    required this.repository,
    required this.audioService,
    required this.onTransitionStatus,
  });

  void start() {
    triggerAutoCancelExpired();
    _startPeriodicTimer();
  }

  void resetAlerts() {
    _alertedStartBookingIds.clear();
  }

  void triggerAutoCancelExpired() {
    repository.autoCancelExpiredBookings().then((_) {
      debugPrint('🟢 [BookingSessionScheduler] autoCancelExpiredBookings completed');
    }).catchError((e) {
      debugPrint('⚠️ [BookingSessionScheduler] autoCancelExpiredBookings error: $e');
    });
  }

  void checkBookingStartTimesAndNotify(List<Booking> bookings) {
    final now = DateTime.now();

    for (final booking in bookings) {
      if (booking.status == BookingStatus.upcoming || booking.status == BookingStatus.pending) {
        final start = booking.startDateTime;
        if (start != null) {
          final diffMinutes = now.difference(start).inMinutes;
          if (diffMinutes >= 0 && diffMinutes <= 5) {
            if (!_alertedStartBookingIds.contains(booking.id)) {
              _alertedStartBookingIds.add(booking.id);
              debugPrint('🔔 [BookingSessionScheduler] Booking ${booking.id} start time arrived!');
              try {
                audioService.playUrgentAlertSound();
              } catch (e) {
                debugPrint('Audio alert error: $e');
              }
            }
          }
        }
      }
    }
  }

  void checkAndAutoTransitionExpiredSessions(List<Booking> bookings) {
    final expiredInProgress = bookings.where((b) {
      return b.status == BookingStatus.inProgress &&
          b.isSessionExpired(null, const Duration(minutes: 5));
    }).toList();

    for (final booking in expiredInProgress) {
      debugPrint('🔄 [BookingSessionScheduler] Auto-transitioning expired session ${booking.id} to completed...');
      onTransitionStatus(booking.id, BookingStatus.completed);
    }
  }

  void _startPeriodicTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      triggerAutoCancelExpired();
    });
  }

  void dispose() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _alertedStartBookingIds.clear();
  }
}
