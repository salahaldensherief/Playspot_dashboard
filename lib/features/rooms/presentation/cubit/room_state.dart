import 'package:equatable/equatable.dart';
import '../../domain/entities/room_entity.dart';

enum RoomStatus { initial, loading, success, failure }

class RoomState extends Equatable {
  final RoomStatus status;
  final List<RoomEntity> rooms;
  final Set<String> updatingRoomIds;
  final String? errorMessage;

  const RoomState({
    this.status = RoomStatus.initial,
    this.rooms = const [],
    this.updatingRoomIds = const {},
    this.errorMessage,
  });

  bool isRoomUpdating(String roomId) => updatingRoomIds.contains(roomId);

  RoomState copyWith({
    RoomStatus? status,
    List<RoomEntity>? rooms,
    Set<String>? updatingRoomIds,
    String? errorMessage,
  }) {
    return RoomState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      updatingRoomIds: updatingRoomIds ?? this.updatingRoomIds,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, rooms, updatingRoomIds, errorMessage];
}
