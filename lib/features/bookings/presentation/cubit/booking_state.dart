import 'package:equatable/equatable.dart';
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
