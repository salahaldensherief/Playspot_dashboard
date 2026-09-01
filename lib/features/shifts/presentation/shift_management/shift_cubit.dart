import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/use_cases/get_active_shift_use_case.dart';
import '../../domain/use_cases/get_lounge_live_shift_overview_use_case.dart';
import '../../domain/use_cases/open_shift_use_case.dart';
import '../../domain/use_cases/close_shift_use_case.dart';
import '../../domain/repositories/shift_repository.dart';
import 'shift_state.dart';

class ShiftCubit extends Cubit<ShiftState> {
  final GetActiveShiftUseCase getActiveShiftUseCase;
  final GetLoungeLiveShiftOverviewUseCase getLoungeLiveShiftOverviewUseCase;
  final OpenShiftUseCase openShiftUseCase;
  final CloseShiftUseCase closeShiftUseCase;
  final ShiftRepository repository;

  ShiftCubit({
    required this.getActiveShiftUseCase,
    required this.getLoungeLiveShiftOverviewUseCase,
    required this.openShiftUseCase,
    required this.closeShiftUseCase,
    required this.repository,
  }) : super(ShiftState.initial());

  /// Fetches a high-level overview for Admins
  Future<void> getLiveShiftOverview(String loungeId) async {
    if (loungeId.isEmpty) {
      emit(state.copyWith(status: ShiftStatus.initial));
      return;
    }
    if (isClosed) return;
    emit(state.copyWith(status: ShiftStatus.loading));
    
    final result = await getLoungeLiveShiftOverviewUseCase(loungeId);
    
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(status: ShiftStatus.error, errorMessage: failure.message)),
      (overview) => emit(state.copyWith(status: ShiftStatus.active, liveOverview: overview)),
    );
  }

  /// Verification check for personal cashier shift
  Future<void> checkActiveShift(String loungeId) async {
    if (loungeId.isEmpty) {
      emit(state.copyWith(status: ShiftStatus.initial, activeShift: null));
      return;
    }
    if (isClosed) return;
    emit(state.copyWith(status: ShiftStatus.loading));
    
    try {
      final result = await getActiveShiftUseCase(loungeId);
      
      if (isClosed) return;
      result.fold(
        (failure) => emit(state.copyWith(status: ShiftStatus.error, errorMessage: failure.message)),
        (shift) {
          if (shift != null) {
            emit(state.copyWith(status: ShiftStatus.active, activeShift: shift));
          } else {
            // No shift found - purely informative reset to initial
            emit(state.copyWith(status: ShiftStatus.initial, activeShift: null));
          }
        },
      );
    } catch (e) {
      emit(state.copyWith(status: ShiftStatus.error, errorMessage: e.toString()));
    }
  }

  /// Combined Open & Verify logic to break silent failure loops
  Future<void> openShift(String loungeId, double startingCash) async {
    if (isClosed) return;
    
    if (loungeId.isEmpty || loungeId == 'null') {
      emit(state.copyWith(
        status: ShiftStatus.error, 
        errorMessage: 'Cannot open shift: No Lounge ID assigned to this account.'
      ));
      return;
    }

    emit(state.copyWith(status: ShiftStatus.loading));
    
    try {
      // 1. Attempt to open/insert shift
      final openResult = await openShiftUseCase(loungeId, startingCash);
      
      if (isClosed) return;

      await openResult.fold(
        (failure) async {
          emit(state.copyWith(status: ShiftStatus.error, errorMessage: failure.message));
        },
        (_) async {
          // 2. Immediately verify if the shift is now visible/queryable
          debugPrint('🔵 [ShiftCubit] Open success, verifying shift sync...');
          final verifyResult = await getActiveShiftUseCase(loungeId);
          
          if (isClosed) return;

          verifyResult.fold(
            (failure) => emit(state.copyWith(status: ShiftStatus.error, errorMessage: failure.message)),
            (shift) {
              if (shift != null) {
                debugPrint('🟢 [ShiftCubit] Shift verified and synced.');
                emit(state.copyWith(status: ShiftStatus.active, activeShift: shift));
              } else {
                // BREAK THE LOOP: If DB said OK but verify says Null, it's an RLS/Sync error.
                // Do not emit .initial as it triggers the dialog again.
                debugPrint('🔴 [ShiftCubit] Shift was created but sync returned null.');
                emit(state.copyWith(
                  status: ShiftStatus.error, 
                  errorMessage: 'Shift created but failed to sync from database. Check Supabase RLS policies.'
                ));
              }
            },
          );
        },
      );
    } catch (e) {
      emit(state.copyWith(status: ShiftStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> closeShift(String shiftId, double actualCash, String? notes, String loungeId) async {
    if (isClosed) return;
    emit(state.copyWith(status: ShiftStatus.loading));
    
    try {
      final result = await closeShiftUseCase(shiftId, actualCash, notes);
      
      if (isClosed) return;
      result.fold(
        (failure) => emit(state.copyWith(status: ShiftStatus.error, errorMessage: failure.message)),
        (closedShift) {
          emit(state.copyWith(
            status: ShiftStatus.closed, 
            lastClosedShift: closedShift,
            activeShift: null,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(status: ShiftStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> fetchShiftHistory({String? loungeId}) async {
    if (loungeId == null || loungeId.isEmpty) {
      emit(state.copyWith(status: ShiftStatus.initial, shifts: []));
      return;
    }
    if (isClosed) return;
    emit(state.copyWith(status: ShiftStatus.loading));
    final result = await repository.getShiftHistory(loungeId: loungeId);
    
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(status: ShiftStatus.error, errorMessage: failure.message)),
      (shifts) => emit(state.copyWith(status: ShiftStatus.active, shifts: shifts)),
    );
  }

  Future<void> approveShift(String shiftId, String managerId, String? notes, {String? loungeId}) async {
    if (isClosed) return;
    emit(state.copyWith(status: ShiftStatus.loading));
    
    final result = await repository.approveShift(shiftId, managerId, notes);
    
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(status: ShiftStatus.error, errorMessage: failure.message)),
      (_) {
        fetchShiftHistory(loungeId: loungeId);
      },
    );
  }

  void resetToInitial() {
    if (!isClosed) emit(ShiftState.initial());
  }
}
