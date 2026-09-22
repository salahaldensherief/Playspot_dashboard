import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/utils/realtime_watcher_mixin.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';
import '../../domain/entities/room_entity.dart';
import '../../domain/repositories/room_repository.dart';

class RoomCubit extends Cubit<RoomState> with RealtimeWatcherMixin<RoomState> {
  final RoomRepository _repository;

  RoomCubit(this._repository) : super(const RoomState());

  void watchRooms(String? loungeId, {bool forceRefresh = false}) {
    final cleanLoungeId = (loungeId != null && loungeId.trim().isNotEmpty) ? loungeId.trim() : null;
    if (cleanLoungeId == null) {
      emit(state.copyWith(
        status: RoomStatus.failure,
        errorMessage: 'Lounge ID is required to watch rooms',
      ));
      return;
    }

    if (isAlreadyWatching(cleanLoungeId, forceRefresh: forceRefresh)) {
      return;
    }

    emit(state.copyWith(status: RoomStatus.loading));
    startWatch<List<RoomEntity>>(
      entityId: cleanLoungeId,
      stream: _repository.watchRooms(cleanLoungeId),
      onData: (rooms) {
        emit(state.copyWith(
          status: RoomStatus.success,
          rooms: rooms,
        ));
      },
      onError: (e) async {
        if (state.rooms.isNotEmpty) {
          emit(state.copyWith(status: RoomStatus.success));
          return;
        }
        final result = await _repository.getRooms(cleanLoungeId);
        if (isClosed) return;
        result.fold(
          (failure) => emit(state.copyWith(
            status: RoomStatus.failure,
            errorMessage: failure.message,
          )),
          (rooms) => emit(state.copyWith(
            status: RoomStatus.success,
            rooms: rooms,
          )),
        );
      },
    );
  }

  Future<void> toggleWalkInStatus(String roomId, RoomStatusEnum currentStatus) async {
    if (state.isRoomUpdating(roomId)) return;

    final newStatus = currentStatus == RoomStatusEnum.occupied
        ? RoomStatusEnum.available
        : RoomStatusEnum.occupied;

    final updatedUpdatingIds = Set<String>.from(state.updatingRoomIds)..add(roomId);
    final previousRooms = List<RoomEntity>.from(state.rooms);
    final updatedRooms = state.rooms.map((room) {
      if (room.id == roomId) {
        return RoomEntity(
          id: room.id,
          loungeId: room.loungeId,
          nameAr: room.nameAr,
          nameEn: room.nameEn,
          descriptionAr: room.descriptionAr,
          descriptionEn: room.descriptionEn,
          activityNames: room.activityNames,
          activityIds: room.activityIds,
          spaceType: room.spaceType,
          spaceTypeId: room.spaceTypeId,
          maxCapacity: room.maxCapacity,
          hourlyRateSingle: room.hourlyRateSingle,
          hourlyRateMulti: room.hourlyRateMulti,
          extraControllerPrice: room.extraControllerPrice,
          isAvailable: room.isAvailable,
          images: room.images,
          featuresAr: room.featuresAr,
          featuresEn: room.featuresEn,
          controllersCount: room.controllersCount,
          screenSize: room.screenSize,
          status: newStatus,
          hasOffer: room.hasOffer,
          offerTitle: room.offerTitle,
          offerTag: room.offerTag,
          activePromotionId: room.activePromotionId,
        );
      }
      return room;
    }).toList();

    emit(state.copyWith(
      rooms: updatedRooms,
      updatingRoomIds: updatedUpdatingIds,
    ));

    final result = await _repository.updateRoomStatus(roomId, newStatus);

    if (isClosed) return;

    final clearedUpdatingIds = Set<String>.from(state.updatingRoomIds)..remove(roomId);

    result.fold(
      (failure) {
        emit(state.copyWith(
          rooms: previousRooms,
          updatingRoomIds: clearedUpdatingIds,
          status: RoomStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (_) {
        emit(state.copyWith(updatingRoomIds: clearedUpdatingIds));
      },
    );
  }

  Future<void> toggleRoomStatus(String roomId, RoomStatusEnum currentStatus) async {
    final newStatus = currentStatus == RoomStatusEnum.available 
        ? RoomStatusEnum.maintenance 
        : RoomStatusEnum.available;
    
    final result = await _repository.updateRoomStatus(roomId, newStatus);
    
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: RoomStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => null,
    );
  }

  Future<void> addNewRoom(RoomEntity room) async {
    emit(state.copyWith(status: RoomStatus.loading));
    final result = await _repository.addRoom(room);
    
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: RoomStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => null,
    );
  }

  Future<void> updateRoom(RoomEntity room) async {
    emit(state.copyWith(status: RoomStatus.loading));
    final result = await _repository.updateRoom(room);
    
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: RoomStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => null,
    );
  }

  Future<void> deleteRoom(String roomId) async {
    emit(state.copyWith(status: RoomStatus.loading));
    final result = await _repository.deleteRoom(roomId);
    
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: RoomStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => null,
    );
  }
}
