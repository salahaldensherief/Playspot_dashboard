import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/shift_params.dart';
import '../../data/repos/shift_repos.dart';
import 'shift_state.dart';

class ShiftCubit extends Cubit<ShiftState> {
  final ShiftRepository _repository;

  ShiftCubit(this._repository) : super(ShiftState.init());

  Future<void> checkActiveShift(String cashierId) async {
    emit(state.copyWith(status: ShiftStatus.loading));
    final result = await _repository.getActiveShift(cashierId);
    
    result.fold(
      (failure) => emit(state.copyWith(status: ShiftStatus.failure, errorMessage: failure.message)),
      (shift) {
        if (shift != null) {
          emit(state.copyWith(status: ShiftStatus.active, activeShift: shift));
        } else {
          emit(state.copyWith(status: ShiftStatus.noActive, activeShift: null));
        }
      },
    );
  }

  Future<void> openShift(OpenShiftParams params) async {
    emit(state.copyWith(status: ShiftStatus.loading));
    final result = await _repository.openShift(params);
    
    result.fold(
      (failure) => emit(state.copyWith(status: ShiftStatus.failure, errorMessage: failure.message)),
      (_) => checkActiveShift(params.cashierId),
    );
  }

  Future<void> closeShift(CloseShiftParams params) async {
    emit(state.copyWith(status: ShiftStatus.loading));
    final result = await _repository.closeShift(params);

    result.fold(
      (failure) => emit(state.copyWith(status: ShiftStatus.failure, errorMessage: failure.message)),
      (closedShift) {
        emit(state.copyWith(
          status: ShiftStatus.closed,
          activeShift: null,
          closedShiftReport: closedShift,
        ));
      },
    );
  }

  Future<void> fetchShiftHistory({String? loungeId}) async {
    emit(state.copyWith(status: ShiftStatus.loading));
    final result = await _repository.getShifts(loungeId: loungeId);
    
    result.fold(
      (failure) => emit(state.copyWith(status: ShiftStatus.failure, errorMessage: failure.message)),
      (shifts) => emit(state.copyWith(status: ShiftStatus.success, shifts: shifts)),
    );
  }
  
  void resetReport() => emit(state.copyWith(closedShiftReport: null));
}
