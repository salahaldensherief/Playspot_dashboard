import 'package:equatable/equatable.dart';
import '../../domain/entities/room_entity.dart';
import '../../domain/entities/room_space_type.dart';

enum RoomStatus { initial, loading, success, failure }

class RoomState extends Equatable {
  final RoomStatus status;
  final List<RoomEntity> rooms;
  final Set<String> updatingRoomIds;
  final String? errorMessage;
  final List<RoomSpaceType> spaceTypes;
  final RoomStatus spaceTypesStatus;

  const RoomState({
    this.status = RoomStatus.initial,
    this.rooms = const [],
    this.updatingRoomIds = const {},
    this.errorMessage,
    this.spaceTypes = const [],
    this.spaceTypesStatus = RoomStatus.initial,
  });

  bool isRoomUpdating(String roomId) => updatingRoomIds.contains(roomId);

  RoomState copyWith({
    RoomStatus? status,
    List<RoomEntity>? rooms,
    Set<String>? updatingRoomIds,
    String? errorMessage,
    List<RoomSpaceType>? spaceTypes,
    RoomStatus? spaceTypesStatus,
  }) {
    return RoomState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      updatingRoomIds: updatingRoomIds ?? this.updatingRoomIds,
      errorMessage: errorMessage ?? this.errorMessage,
      spaceTypes: spaceTypes ?? this.spaceTypes,
      spaceTypesStatus: spaceTypesStatus ?? this.spaceTypesStatus,
    );
  }

  @override
  List<Object?> get props => [
    status,
    rooms,
    updatingRoomIds,
    errorMessage,
    spaceTypes,
    spaceTypesStatus,
  ];
}
