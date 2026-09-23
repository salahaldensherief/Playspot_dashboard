import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/shift_entity.dart';
import '../../domain/entities/shift_expense_entity.dart';
import '../../domain/repositories/shift_repository.dart';
import '../../domain/use_cases/close_shift_use_case.dart';
import '../../domain/use_cases/get_active_shift_use_case.dart';
import '../../domain/use_cases/get_lounge_live_shift_overview_use_case.dart';
import '../../domain/use_cases/open_shift_use_case.dart';
import 'shift_details_fetcher.dart';
import 'shift_realtime_subscription_manager.dart';
import 'shift_state.dart';

class ShiftCubit extends Cubit<ShiftState> {
  final GetActiveShiftUseCase getActiveShiftUseCase;
  final GetLoungeLiveShiftOverviewUseCase getLoungeLiveShiftOverviewUseCase;
  final OpenShiftUseCase openShiftUseCase;
  final CloseShiftUseCase closeShiftUseCase;
  final ShiftRepository repository;
  final ShiftRealtimeSubscriptionManager _realtimeManager;
  final ShiftDetailsFetcher _detailsFetcher;

  ShiftCubit({
    required this.getActiveShiftUseCase,
    required this.getLoungeLiveShiftOverviewUseCase,
    required this.openShiftUseCase,
    required this.closeShiftUseCase,
    required this.repository,
    SupabaseClient? supabaseClient,
  })  : _realtimeManager = ShiftRealtimeSubscriptionManager(supabaseClient),
        _detailsFetcher = ShiftDetailsFetcher(repository),
        super(ShiftState.initial());

  void setupRealtimeSubscription(String loungeId) {
    _realtimeManager.subscribe(
      loungeId: loungeId,
      onShiftChanged: () => checkActiveShift(loungeId),
      onOverviewChanged: () => getLiveShiftOverview(loungeId),
    );
  }

  @override
  Future<void> close() {
    _realtimeManager.unsubscribe();
    return super.close();
  }

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
          emit(state.copyWith(
            status: shift != null ? ShiftStatus.active : ShiftStatus.initial,
            activeShift: shift,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(status: ShiftStatus.error, errorMessage: e.toString()));
    }
  }

  Future<bool> _verifyAndSyncShift(String loungeId) async {
    final verifyResult = await getActiveShiftUseCase(loungeId);
    if (isClosed) return false;

    return verifyResult.fold(
      (failure) {
        emit(state.copyWith(status: ShiftStatus.error, errorMessage: failure.message));
        return false;
      },
      (shift) {
        if (shift != null) {
          debugPrint('🟢 [ShiftCubit] Shift verified & active.');
          emit(state.copyWith(status: ShiftStatus.active, activeShift: shift));
          getLiveShiftOverview(loungeId);
          return true;
        } else {
          debugPrint('🔴 [ShiftCubit] Shift created but verify returned null.');
          emit(state.copyWith(
            status: ShiftStatus.error,
            errorMessage: 'Shift created but failed to sync from database.',
          ));
          return false;
        }
      },
    );
  }

  Future<void> openShift(String loungeId, double startingCash) async {
    if (isClosed) return;
    if (loungeId.isEmpty || loungeId == 'null') {
      emit(state.copyWith(
        status: ShiftStatus.error,
        errorMessage: 'Cannot open shift: No Lounge ID assigned to this account.',
      ));
      return;
    }

    emit(state.copyWith(status: ShiftStatus.loading));
    try {
      final openResult = await openShiftUseCase(loungeId, startingCash);
      if (isClosed) return;

      await openResult.fold(
        (failure) async => emit(state.copyWith(status: ShiftStatus.error, errorMessage: failure.message)),
        (_) => _verifyAndSyncShift(loungeId),
      );
    } catch (e) {
      emit(state.copyWith(status: ShiftStatus.error, errorMessage: e.toString()));
    }
  }

  Future<bool> quickOpenShift(String loungeId, [double startingCash = 0.0]) async {
    if (isClosed) return false;
    if (loungeId.isEmpty || loungeId == 'null') {
      emit(state.copyWith(
        status: ShiftStatus.error,
        errorMessage: 'Cannot open shift: No Lounge ID assigned.',
      ));
      return false;
    }

    emit(state.copyWith(status: ShiftStatus.loading));
    try {
      final openResult = await repository.quickOpenShift(loungeId, startingCash);
      if (isClosed) return false;

      return await openResult.fold(
        (failure) {
          emit(state.copyWith(status: ShiftStatus.error, errorMessage: failure.message));
          return false;
        },
        (_) => _verifyAndSyncShift(loungeId),
      );
    } catch (e) {
      emit(state.copyWith(status: ShiftStatus.error, errorMessage: e.toString()));
      return false;
    }
  }

  Future<void> closeShift(String shiftId, double actualCash, String? notes, String loungeId) async {
    if (isClosed) return;
    emit(state.copyWith(status: ShiftStatus.loading));

    try {
      final result = await closeShiftUseCase(shiftId, actualCash, notes, loungeId: loungeId);
      if (isClosed) return;

      result.fold(
        (failure) => emit(state.copyWith(status: ShiftStatus.error, errorMessage: failure.message)),
        (closedShift) {
          emit(state.copyWith(
            status: ShiftStatus.closed,
            lastClosedShift: closedShift,
            activeShift: null,
          ));
          getLiveShiftOverview(loungeId);
        },
      );
    } catch (e) {
      emit(state.copyWith(status: ShiftStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> fetchShiftHistory({String? loungeId}) async {
    if (isClosed) return;
    emit(state.copyWith(status: ShiftStatus.loading));
    final result = await repository.getShiftHistory(loungeId: loungeId);

    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(status: ShiftStatus.error, errorMessage: failure.message)),
      (shifts) => emit(state.copyWith(status: ShiftStatus.active, shifts: shifts)),
    );
  }

  Future<void> fetchShiftReport({
    String? loungeId,
    DateTime? startDate,
    DateTime? endDate,
    String? cashierId,
  }) async {
    if (isClosed) return;
    emit(state.copyWith(status: ShiftStatus.loading));
    final result = await repository.getShiftReport(
      loungeId: loungeId,
      startDate: startDate,
      endDate: endDate,
      cashierId: cashierId,
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(status: ShiftStatus.error, errorMessage: failure.message)),
      (shifts) => emit(state.copyWith(status: ShiftStatus.active, shifts: shifts)),
    );
  }

  Future<void> getCashierPerformance({
    String? loungeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (isClosed) return;
    final result = await repository.getCashierPerformance(
      loungeId: loungeId,
      startDate: startDate,
      endDate: endDate,
    );

    if (isClosed) return;
    result.fold(
      (failure) => debugPrint('🔴 [ShiftCubit] Cashier performance failed: ${failure.message}'),
      (list) => emit(state.copyWith(cashierPerformances: list)),
    );
  }

  Future<void> getLoungeComparison({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (isClosed) return;
    final result = await repository.getLoungeComparison(
      startDate: startDate,
      endDate: endDate,
    );

    if (isClosed) return;
    result.fold(
      (failure) => debugPrint('🔴 [ShiftCubit] Lounge comparison failed: ${failure.message}'),
      (list) => emit(state.copyWith(loungeComparisons: list)),
    );
  }

  Future<void> fetchShiftDetails(ShiftEntity shift) async {
    if (isClosed) return;
    emit(state.copyWith(selectedShiftDetails: shift));

    final updatedState = await _detailsFetcher.fetchDetails(
      shift: shift,
      currentState: state,
    );
    if (!isClosed) emit(updatedState);
  }

  Future<void> fetchShiftExpenses(String shiftId) async {
    if (shiftId.isEmpty || isClosed) return;
    final result = await repository.fetchShiftExpenses(shiftId);
    if (isClosed) return;

    result.fold(
      (failure) => debugPrint('🔴 [ShiftCubit] Fetch Expenses Failed: ${failure.message}'),
      (expenses) => emit(state.copyWith(expenses: expenses)),
    );
  }

  Future<bool> addShiftExpense({
    required String shiftId,
    required String loungeId,
    required double amount,
    required String reason,
    required String type,
  }) async {
    if (isClosed) return false;

    final expense = ShiftExpenseEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      shiftId: shiftId,
      loungeId: loungeId,
      amount: amount,
      type: type,
      reason: reason,
      createdAt: DateTime.now(),
    );

    final result = await repository.addShiftExpense(expense);
    if (isClosed) return false;

    return result.fold(
      (failure) {
        debugPrint('🔴 [ShiftCubit] Add Expense Failed: ${failure.message}');
        emit(state.copyWith(status: ShiftStatus.error, errorMessage: failure.message));
        return false;
      },
      (_) async {
        debugPrint('🟢 [ShiftCubit] Add Expense Succeeded');
        await fetchShiftExpenses(shiftId);
        getLiveShiftOverview(loungeId);
        return true;
      },
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
        if (loungeId != null) getLiveShiftOverview(loungeId);
      },
    );
  }

  void resetToInitial() {
    if (!isClosed) emit(ShiftState.initial());
  }
}
