import 'package:equatable/equatable.dart';

class Room extends Equatable {
  final String id;
  final String loungeId;
  final String name;
  final String type; // e.g., VIP, Standard

  const Room({
    required this.id,
    required this.loungeId,
    required this.name,
    required this.type,
  });

  @override
  List<Object?> get props => [id, loungeId, name, type];
}
