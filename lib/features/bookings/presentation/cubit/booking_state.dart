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
  final Booking? latestNewBooking;

  const BookingState({
    this.status = BookingStatusState.initial,
    this.bookings = const [],
    this.page = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.errorMessage,
    this.selectedDurationMinutes = 60,
    this.latestNewBooking,
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
        .where((b) => isBookingInCurrentShiftOrToday(b, activeShift, userLounge: userLounge, requireCompleted: true))
        .toList();
  }

  /// Current Shift / Today Revenue
  double currentShiftRevenue({dynamic activeShift, Lounge? userLounge}) {
    return currentShiftBookings(activeShift: activeShift, userLounge: userLounge)
        .fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// Core logic for checking if a booking belongs to current active shift or today's operational day
  static bool isBookingInCurrentShiftOrToday(
    Booking booking,
    dynamic activeShift, {
    Lounge? userLounge,
    bool requireCompleted = false,
  }) {
    if (requireCompleted && booking.status != BookingStatus.completed) return false;
    if (booking.status == BookingStatus.cancelled) return false;

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
    final DateTime operationalDayEnd = operationalDayStart.add(const Duration(hours: 24));

    final bookingTime = booking.checkedInAt ??
        booking.startDateTime ??
        DateTime(booking.date.year, booking.date.month, booking.date.day, 12, 0);

    final bool isInOperationalDay =
        (bookingTime.isAfter(operationalDayStart) || bookingTime.isAtSameMomentAs(operationalDayStart)) &&
            bookingTime.isBefore(operationalDayEnd);

    if (activeShift != null) {
      if (booking.shiftId != null && booking.shiftId == activeShift.id) {
        return isInOperationalDay;
      }
      final DateTime startTime = activeShift.startTime;
      final bool isAfterShiftStart = bookingTime.isAfter(startTime.subtract(const Duration(minutes: 15))) ||
          bookingTime.isAtSameMomentAs(startTime.subtract(const Duration(minutes: 15)));
      return isAfterShiftStart && isInOperationalDay;
    }

    return isInOperationalDay;
  }

  BookingState copyWith({
    BookingStatusState? status,
    List<Booking>? bookings,
    int? page,
    int? pageSize,
    int? totalCount,
    String? errorMessage,
    int? selectedDurationMinutes,
    Booking? latestNewBooking,
    bool clearLatestNewBooking = false,
  }) {
    return BookingState(
      status: status ?? this.status,
      bookings: bookings ?? this.bookings,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedDurationMinutes: selectedDurationMinutes ?? this.selectedDurationMinutes,
      latestNewBooking: clearLatestNewBooking ? null : (latestNewBooking ?? this.latestNewBooking),
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
        latestNewBooking,
      ];
}
