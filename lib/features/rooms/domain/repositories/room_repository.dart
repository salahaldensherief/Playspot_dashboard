import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../entities/room_entity.dart';

abstract class RoomRepository {
  Future<Either<Failure, List<RoomEntity>>> getRooms(String loungeId);
  Stream<List<RoomEntity>> watchRooms(String loungeId);
  Future<Either<Failure, void>> updateRoomStatus(String roomId, RoomStatusEnum status);
  Future<Either<Failure, void>> addRoom(RoomEntity room);
  Future<Either<Failure, void>> updateRoom(RoomEntity room);
  Future<Either<Failure, void>> deleteRoom(String roomId);
}
