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
        // If state already has loaded rooms (e.g. from initial REST yield), keep displaying them
        if (state.rooms.isNotEmpty) {
          emit(state.copyWith(status: RoomStatus.success));
          return;
        }
        // Otherwise, attempt a direct REST fetch as fallback
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
