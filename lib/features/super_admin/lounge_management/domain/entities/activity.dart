import 'package:equatable/equatable.dart';

class Activity extends Equatable {
  final String id;
  final String roomId;
  final String name;
  final double pricePerHour;
  final String type; // e.g., PS5, PC, Billiards

  const Activity({
    required this.id,
    required this.roomId,
    required this.name,
    required this.pricePerHour,
    required this.type,
  });

  @override
  List<Object?> get props => [id, roomId, name, pricePerHour, type];
}
