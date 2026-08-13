import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/rooms/domain/repositories/room_repository.dart';
import 'package:play_spot_dashboard/features/rooms/data/datasources/room_remote_data_source.dart';
import 'package:play_spot_dashboard/features/rooms/data/models/room_model.dart';

class RoomRepositoryImpl implements RoomRepository {
  final RoomRemoteDataSource _remoteSource;

  RoomRepositoryImpl(this._remoteSource);

  @override
  Future<Either<Failure, List<RoomEntity>>> getRooms(String loungeId) async {
    try {
      final rooms = await _remoteSource.getRooms(loungeId);
      return Right(rooms);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<RoomEntity>> watchRooms(String loungeId) {
    return _remoteSource.watchRooms(loungeId);
  }

  @override
  Future<Either<Failure, void>> updateRoomStatus(String roomId, RoomStatusEnum status) async {
    try {
      await _remoteSource.updateRoomStatus(roomId, status == RoomStatusEnum.maintenance ? 'maintenance' : 'available');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addRoom(RoomEntity room) async {
    try {
      await _remoteSource.addRoom(RoomModel(
        id: room.id,
        loungeId: room.loungeId,
        nameAr: room.nameAr,
        nameEn: room.nameEn,
        activityNames: room.activityNames,
        activityIds: room.activityIds,
        spaceType: room.spaceType,
        spaceTypeId: room.spaceTypeId ?? '',
        pricePerHourSingle: room.pricePerHourSingle,
        pricePerHourMulti: room.pricePerHourMulti,
        pricePerHour: room.pricePerHourSingle,
        isAvailable: room.isAvailable,
        status: room.status,
        capacity: room.capacity,
        featuresAr: room.featuresAr,
        featuresEn: room.featuresEn,
        images: room.images,
        controllersCount: room.controllersCount,
        screenSize: room.screenSize,
      ));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateRoom(RoomEntity room) async {
    try {
      await _remoteSource.updateRoom(RoomModel(
        id: room.id,
        loungeId: room.loungeId,
        nameAr: room.nameAr,
        nameEn: room.nameEn,
        activityNames: room.activityNames,
        activityIds: room.activityIds,
        spaceType: room.spaceType,
        spaceTypeId: room.spaceTypeId ?? '',
        pricePerHourSingle: room.pricePerHourSingle,
        pricePerHourMulti: room.pricePerHourMulti,
        pricePerHour: room.pricePerHourSingle,
        isAvailable: room.isAvailable,
        status: room.status,
        capacity: room.capacity,
        featuresAr: room.featuresAr,
        featuresEn: room.featuresEn,
        images: room.images,
        controllersCount: room.controllersCount,
        screenSize: room.screenSize,
      ));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRoom(String roomId) async {
    try {
      await _remoteSource.deleteRoom(roomId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
