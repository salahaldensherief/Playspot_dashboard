import 'package:equatable/equatable.dart';
import '../../domain/entities/room_entity.dart';

enum RoomStatus { initial, loading, success, failure }

class RoomState extends Equatable {
  final RoomStatus status;
  final List<RoomEntity> rooms;
  final String? errorMessage;

  const RoomState({
    this.status = RoomStatus.initial,
    this.rooms = const [],
    this.errorMessage,
  });

  RoomState copyWith({
    RoomStatus? status,
    List<RoomEntity>? rooms,
    String? errorMessage,
  }) {
    return RoomState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, rooms, errorMessage];
}
