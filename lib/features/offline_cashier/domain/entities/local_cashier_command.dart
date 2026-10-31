import 'package:equatable/equatable.dart';

enum LocalCashierCommandKind { reserve, start, addItems, collectCash, close }

class LocalCashierCommand extends Equatable {
  final String id;
  final String bookingId;
  final String actorId;
  final String loungeId;
  final String deviceId;
  final String permitId;
  final String shiftId;
  final DateTime occurredAt;
  final LocalCashierCommandKind kind;
  final Map<String, dynamic> payload;

  LocalCashierCommand({
    required this.id,
    required this.bookingId,
    required this.actorId,
    required this.loungeId,
    required this.deviceId,
    required this.permitId,
    required this.shiftId,
    required this.occurredAt,
    required this.kind,
    required Map<String, dynamic> payload,
  }) : payload = _immutablePayload(payload) as Map<String, dynamic>;

  @override
  List<Object?> get props => [
    id,
    bookingId,
    actorId,
    loungeId,
    deviceId,
    permitId,
    shiftId,
    occurredAt,
    kind,
    payload,
  ];
}

Object? _immutablePayload(Object? value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.unmodifiable(
      value.map((key, item) => MapEntry(key, _immutablePayload(item))),
    );
  }
  if (value is List) return List.unmodifiable(value.map(_immutablePayload));
  return value;
}
