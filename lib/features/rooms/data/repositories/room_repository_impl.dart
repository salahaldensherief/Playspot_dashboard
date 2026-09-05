import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/core/services/local_cache_service.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/rooms/domain/repositories/room_repository.dart';
import 'package:play_spot_dashboard/features/rooms/data/datasources/room_remote_data_source.dart';
import 'package:play_spot_dashboard/features/rooms/data/models/room_model.dart';

class RoomRepositoryImpl implements RoomRepository {
  final RoomRemoteDataSource _remoteSource;
  final LocalCacheService _localCacheService;

  RoomRepositoryImpl(this._remoteSource, this._localCacheService);

  @override
  Future<Either<Failure, List<RoomEntity>>> getRooms(String loungeId, {bool forceRefresh = false}) async {
    final cacheKey = 'cache_rooms_$loungeId';
    try {
      if (!forceRefresh) {
        final cached = _localCacheService.getJson(cacheKey);
        if (cached is List && cached.isNotEmpty) {
          final cachedRooms = cached
              .map((item) => RoomModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .map((m) => m as RoomEntity)
              .toList();
          _refreshRoomsInBackground(loungeId, cacheKey);
          return Right(cachedRooms);
        }
      }

      final rooms = await _remoteSource.getRooms(loungeId);
      final roomModels = rooms.map((r) => RoomModel(
        id: r.id,
        loungeId: r.loungeId,
        nameAr: r.nameAr,
        nameEn: r.nameEn,
        descriptionAr: r.descriptionAr,
        descriptionEn: r.descriptionEn,
        activityNames: r.activityNames,
        activityIds: r.activityIds,
        spaceType: r.spaceType,
        spaceTypeId: r.spaceTypeId ?? '',
        capacity: r.capacity,
        pricePerHourSingle: r.pricePerHourSingle,
        pricePerHourMulti: r.pricePerHourMulti,
        pricePerHour: r.pricePerHour,
        extraControllerPrice: r.extraControllerPrice,
        isAvailable: r.isAvailable,
        images: r.images,
        featuresAr: r.featuresAr,
        featuresEn: r.featuresEn,
        controllersCount: r.controllersCount,
        screenSize: r.screenSize,
        status: r.status,
      )).toList();

      await _localCacheService.setJson(cacheKey, roomModels.map((m) => m.toJson()).toList());
      return Right(rooms);
    } catch (e) {
      final cached = _localCacheService.getJson(cacheKey);
      if (cached is List && cached.isNotEmpty) {
        final cachedRooms = cached
            .map((item) => RoomModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .map((m) => m as RoomEntity)
            .toList();
        return Right(cachedRooms);
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  void _refreshRoomsInBackground(String loungeId, String cacheKey) async {
    try {
      final rooms = await _remoteSource.getRooms(loungeId);
      final roomModels = rooms.map((r) => RoomModel(
        id: r.id,
        loungeId: r.loungeId,
        nameAr: r.nameAr,
        nameEn: r.nameEn,
        descriptionAr: r.descriptionAr,
        descriptionEn: r.descriptionEn,
        activityNames: r.activityNames,
        activityIds: r.activityIds,
        spaceType: r.spaceType,
        spaceTypeId: r.spaceTypeId ?? '',
        capacity: r.capacity,
        pricePerHourSingle: r.pricePerHourSingle,
        pricePerHourMulti: r.pricePerHourMulti,
        pricePerHour: r.pricePerHour,
        extraControllerPrice: r.extraControllerPrice,
        isAvailable: r.isAvailable,
        images: r.images,
        featuresAr: r.featuresAr,
        featuresEn: r.featuresEn,
        controllersCount: r.controllersCount,
        screenSize: r.screenSize,
        status: r.status,
      )).toList();

      await _localCacheService.setJson(cacheKey, roomModels.map((m) => m.toJson()).toList());
    } catch (_) {}
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
        pricePerHour: room.pricePerHour,
        extraControllerPrice: room.extraControllerPrice,
        isAvailable: room.isAvailable,
        status: room.status,
        capacity: room.capacity,
        featuresAr: room.featuresAr,
        featuresEn: room.featuresEn,
        images: room.images,
        controllersCount: room.controllersCount,
        screenSize: room.screenSize,
      ));
      await _localCacheService.remove('cache_rooms_${room.loungeId}');
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
        pricePerHour: room.pricePerHour,
        extraControllerPrice: room.extraControllerPrice,
        isAvailable: room.isAvailable,
        status: room.status,
        capacity: room.capacity,
        featuresAr: room.featuresAr,
        featuresEn: room.featuresEn,
        images: room.images,
        controllersCount: room.controllersCount,
        screenSize: room.screenSize,
      ));
      await _localCacheService.remove('cache_rooms_${room.loungeId}');
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
