import 'package:equatable/equatable.dart';
import '../../../lounges/domain/entities/lounge.dart';
import '../../domain/entities/booking.dart';

enum BookingStatusState { initial, loading, success, failure }

class BookingState extends Equatable {
  final BookingStatusState status;
  final List<Booking> bookings;
  final int page;
  final int pageSize;
  final int totalCount;
  final String? errorMessage;
  final int selectedDurationMinutes;

  const BookingState({
    this.status = BookingStatusState.initial,
    this.bookings = const [],
    this.page = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.errorMessage,
    this.selectedDurationMinutes = 60,
  });

  bool get hasNextPage => page * pageSize < totalCount;
  bool get hasPreviousPage => page > 1;
  int get totalPages => pageSize > 0 ? (totalCount / pageSize).ceil() : 0;

  /// Active Bookings: currently in-progress or upcoming (and not expired)
  List<Booking> get activeBookings => bookings
      .where((b) => b.isBookingActive() || (b.status == BookingStatus.upcoming && !b.isSessionExpired()))
      .toList();

  /// Pending Bookings: waiting for approval
  List<Booking> get pendingBookings => bookings
      .where((b) => b.status == BookingStatus.pending)
      .toList();

  /// Current Shift / Today Bookings
  List<Booking> currentShiftBookings({dynamic activeShift, Lounge? userLounge}) {
    return bookings
        .where((b) => isBookingInCurrentShiftOrToday(b, activeShift, userLounge: userLounge))
        .toList();
  }

  /// Current Shift / Today Revenue
  double currentShiftRevenue({dynamic activeShift, Lounge? userLounge}) {
    return currentShiftBookings(activeShift: activeShift, userLounge: userLounge)
        .fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// Core logic for checking if a booking belongs to current active shift or today's operational day
  static bool isBookingInCurrentShiftOrToday(Booking booking, dynamic activeShift, {Lounge? userLounge}) {
    if (booking.status != BookingStatus.completed) return false;

    // RULE 1: If there is an Active Open Shift -> Operational Day defined by the Open Shift
    if (activeShift != null) {
      if (booking.shiftId != null && booking.shiftId == activeShift.id) {
        return true;
      }
      final DateTime startTime = activeShift.startTime;
      return booking.date.isAfter(startTime.subtract(const Duration(minutes: 15))) ||
          booking.date.isAtSameMomentAs(startTime);
    }

    // RULE 2: If No Active Shift -> Operational Day based on Lounge Opening Hours / 5:00 AM Threshold
    final now = DateTime.now();
    int thresholdHour = 5;

    if (userLounge != null && userLounge.opensAt.isNotEmpty) {
      final parts = userLounge.opensAt.split(':');
      if (parts.isNotEmpty) {
        final parsedHour = int.tryParse(parts[0]);
        if (parsedHour != null && parsedHour >= 0 && parsedHour <= 23) {
          thresholdHour = parsedHour;
        }
      }
    }

    final DateTime operationalDayStart;
    if (now.hour < thresholdHour) {
      final yesterday = now.subtract(const Duration(days: 1));
      operationalDayStart = DateTime(yesterday.year, yesterday.month, yesterday.day, thresholdHour);
    } else {
      operationalDayStart = DateTime(now.year, now.month, now.day, thresholdHour);
    }

    return booking.date.isAfter(operationalDayStart) || booking.date.isAtSameMomentAs(operationalDayStart);
  }

  BookingState copyWith({
    BookingStatusState? status,
    List<Booking>? bookings,
    int? page,
    int? pageSize,
    int? totalCount,
    String? errorMessage,
    int? selectedDurationMinutes,
  }) {
    return BookingState(
      status: status ?? this.status,
      bookings: bookings ?? this.bookings,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedDurationMinutes: selectedDurationMinutes ?? this.selectedDurationMinutes,
    );
  }

  @override
  List<Object?> get props => [
        status,
        bookings,
        page,
        pageSize,
        totalCount,
        errorMessage,
        selectedDurationMinutes,
      ];
}
