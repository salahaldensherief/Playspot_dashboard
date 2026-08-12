import 'package:equatable/equatable.dart';
import '../../domain/entities/booking.dart';

enum BookingStatusState { initial, loading, success, failure }

class BookingState extends Equatable {
  final BookingStatusState status;
  final List<Booking> bookings;
  final String? errorMessage;

  const BookingState({
    this.status = BookingStatusState.initial,
    this.bookings = const [],
    this.errorMessage,
  });

  BookingState copyWith({
    BookingStatusState? status,
    List<Booking>? bookings,
    String? errorMessage,
  }) {
    return BookingState(
      status: status ?? this.status,
      bookings: bookings ?? this.bookings,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, bookings, errorMessage];
}
