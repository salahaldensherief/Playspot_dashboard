import 'package:equatable/equatable.dart';

class CashierConflict extends Equatable {
  final String operationId;
  final String bookingId;
  final String actorId;
  final String kind;
  final String code;
  final int sequence;
  final bool retryPending;

  const CashierConflict({
    required this.operationId,
    required this.bookingId,
    required this.actorId,
    required this.kind,
    required this.code,
    required this.sequence,
    required this.retryPending,
  });

  @override
  List<Object?> get props => [
    operationId,
    bookingId,
    actorId,
    kind,
    code,
    sequence,
    retryPending,
  ];
}
