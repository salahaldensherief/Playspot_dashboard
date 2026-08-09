import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/room_entity.dart';
import '../../domain/repositories/room_repository.dart';

part 'room_state.dart';

class RoomCubit extends Cubit<RoomState> {
  final RoomRepository _repository;
  StreamSubscription? _subscription;

  RoomCubit(this._repository) : super(RoomInitial());

  void watchRooms(String loungeId) {
    emit(RoomLoading());
    _subscription?.cancel();
    _subscription = _repository.watchRooms(loungeId).listen(
      (rooms) => emit(RoomLoaded(rooms)),
      onError: (e) => emit(RoomError(e.toString())),
    );
  }

  Future<void> toggleRoomStatus(String roomId, RoomStatus currentStatus) async {
    final newStatus = currentStatus == RoomStatus.available 
        ? RoomStatus.maintenance 
        : RoomStatus.available;
    
    final result = await _repository.updateRoomStatus(roomId, newStatus);
    result.fold(
      (failure) => emit(RoomError(failure.message)),
      (_) => null, // Real-time subscription will update UI
    );
  }

  Future<void> addNewRoom(RoomEntity room) async {
    final result = await _repository.addRoom(room);
    result.fold(
      (failure) => emit(RoomError(failure.message)),
      (_) => null,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
