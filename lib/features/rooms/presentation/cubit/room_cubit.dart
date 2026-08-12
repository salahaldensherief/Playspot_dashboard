import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/features/rooms/presentation/cubit/room_state.dart';
import '../../domain/entities/room_entity.dart';
import '../../domain/repositories/room_repository.dart';

class RoomCubit extends Cubit<RoomState> {
  final RoomRepository _repository;
  StreamSubscription? _subscription;

  RoomCubit(this._repository) : super(const RoomState());

  void watchRooms(String loungeId) {
    emit(state.copyWith(status: RoomStatus.loading));
    _subscription?.cancel();
    _subscription = _repository.watchRooms(loungeId).listen(
      (rooms) {
        if (isClosed) return;
        emit(state.copyWith(
          status: RoomStatus.success,
          rooms: rooms,
        ));
      },
      onError: (e) {
        if (isClosed) return;
        emit(state.copyWith(
          status: RoomStatus.failure,
          errorMessage: e.toString(),
        ));
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

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
