import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/use_cases/get_current_shift_use_case.dart';
import '../../domain/use_cases/open_shift_use_case.dart';
import '../../domain/use_cases/close_shift_use_case.dart';
import '../../domain/repositories/shift_repository.dart';
import 'shift_state.dart';

class ShiftCubit extends Cubit<ShiftState> {
  final GetCurrentShiftUseCase _getCurrentShiftUseCase;
  final OpenShiftUseCase _openShiftUseCase;
  final CloseShiftUseCase _closeShiftUseCase;
  final ShiftRepository _repository; // Needed for history if not using separate usecase

  ShiftCubit(
    this._getCurrentShiftUseCase,
    this._openShiftUseCase,
    this._closeShiftUseCase,
    this._repository,
  ) : super(ShiftState.init());

  Future<void> checkActiveShift(String loungeId) async {
    emit(state.copyWith(status: ShiftStatus.loading));
    try {
      final shift = await _getCurrentShiftUseCase(loungeId);
      if (shift != null) {
        emit(state.copyWith(status: ShiftStatus.active, activeShift: shift));
      } else {
        emit(state.copyWith(status: ShiftStatus.noActive, activeShift: null));
      }
    } catch (e) {
      emit(state.copyWith(status: ShiftStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> openShift({required String loungeId, required double startingCash}) async {
    emit(state.copyWith(status: ShiftStatus.loading));
    try {
      await _openShiftUseCase(loungeId, startingCash);
      await checkActiveShift(loungeId);
    } catch (e) {
      emit(state.copyWith(status: ShiftStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> closeShift({
    required String shiftId,
    required double actualCash,
    String? notes,
    required String loungeId,
  }) async {
    emit(state.copyWith(status: ShiftStatus.loading));
    try {
      await _closeShiftUseCase(shiftId, actualCash, notes);
      // After closing, we might want to fetch the closed shift details for a report
      // But the RPC close_shift in our data source doesn't return the model yet.
      // Assuming we refetch or the state transition handles it.
      emit(state.copyWith(status: ShiftStatus.closed, activeShift: null));
      await checkActiveShift(loungeId);
    } catch (e) {
      emit(state.copyWith(status: ShiftStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> fetchShiftHistory({String? loungeId}) async {
    emit(state.copyWith(status: ShiftStatus.loading));
    try {
      final shifts = await _repository.getShiftHistory(loungeId: loungeId);
      emit(state.copyWith(status: ShiftStatus.success, shifts: shifts));
    } catch (e) {
      emit(state.copyWith(status: ShiftStatus.failure, errorMessage: e.toString()));
    }
  }

  void resetReport() => emit(state.copyWith(closedShiftReport: null, status: ShiftStatus.noActive));
}
