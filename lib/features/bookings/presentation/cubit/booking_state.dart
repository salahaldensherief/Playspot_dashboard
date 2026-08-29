import 'package:equatable/equatable.dart';
import '../../domain/entities/booking.dart';

enum BookingStatusState { initial, loading, success, failure }

class BookingState extends Equatable {
  final BookingStatusState status;
  final List<Booking> bookings;
  final String? errorMessage;
  final int selectedDurationMinutes;

  const BookingState({
    this.status = BookingStatusState.initial,
    this.bookings = const [],
    this.errorMessage,
    this.selectedDurationMinutes = 60,
  });

  BookingState copyWith({
    BookingStatusState? status,
    List<Booking>? bookings,
    String? errorMessage,
    int? selectedDurationMinutes,
  }) {
    return BookingState(
      status: status ?? this.status,
      bookings: bookings ?? this.bookings,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedDurationMinutes: selectedDurationMinutes ?? this.selectedDurationMinutes,
    );
  }

  @override
  List<Object?> get props => [status, bookings, errorMessage, selectedDurationMinutes];
}
