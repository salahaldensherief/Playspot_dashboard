import 'package:equatable/equatable.dart';

class BookingCancellationHistoryItem extends Equatable {
  final String bookingId;
  final String? roomName;
  final DateTime? date;
  final String? startTime;
  final String? endTime;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  const BookingCancellationHistoryItem({
    required this.bookingId,
    this.roomName,
    this.date,
    this.startTime,
    this.endTime,
    this.cancelledAt,
    this.cancellationReason,
  });

  factory BookingCancellationHistoryItem.fromJson(Map<String, dynamic> json) {
    return BookingCancellationHistoryItem(
      bookingId: (json['booking_id'] ?? json['id'] ?? '').toString(),
      roomName: (json['room_name'] ?? json['rooms']?['name'] ?? json['rooms']?['name_en'])?.toString(),
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      cancelledAt: json['cancelled_at'] != null ? DateTime.tryParse(json['cancelled_at'].toString()) : null,
      cancellationReason: (json['cancellation_reason'] ?? json['reason'])?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        bookingId,
        roomName,
        date,
        startTime,
        endTime,
        cancelledAt,
        cancellationReason,
      ];
}

class CustomerCancellationSummary extends Equatable {
  final int afterApprovalCount;
  final int last90DaysCount;
  final List<BookingCancellationHistoryItem> history;

  const CustomerCancellationSummary({
    required this.afterApprovalCount,
    required this.last90DaysCount,
    required this.history,
  });

  factory CustomerCancellationSummary.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['history'] as List<dynamic>? ?? [];
    return CustomerCancellationSummary(
      afterApprovalCount: (json['after_approval_count'] ?? json['afterApprovalCount'] ?? 0) as int,
      last90DaysCount: (json['last_90_days_count'] ?? json['last90DaysCount'] ?? 0) as int,
      history: rawHistory.map((item) {
        if (item is Map) {
          return BookingCancellationHistoryItem.fromJson(Map<String, dynamic>.from(item));
        }
        return BookingCancellationHistoryItem(bookingId: item.toString());
      }).toList(),
    );
  }

  factory CustomerCancellationSummary.empty() {
    return const CustomerCancellationSummary(
      afterApprovalCount: 0,
      last90DaysCount: 0,
      history: [],
    );
  }

  @override
  List<Object?> get props => [
        afterApprovalCount,
        last90DaysCount,
        history,
      ];
}
