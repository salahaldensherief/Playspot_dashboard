import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/shift_entity.dart';
import '../../domain/entities/shift_expense_entity.dart';
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
  final SupabaseClient? supabaseClient;

  RealtimeChannel? _realtimeChannel;

  ShiftCubit({
    required this.getActiveShiftUseCase,
    required this.getLoungeLiveShiftOverviewUseCase,
    required this.openShiftUseCase,
    required this.closeShiftUseCase,
    required this.repository,
    this.supabaseClient,
  }) : super(ShiftState.initial());

  /// Setup Realtime Subscriptions for live updates
  void setupRealtimeSubscription(String loungeId) {
    if (loungeId.isEmpty) return;
    _realtimeChannel?.unsubscribe();

    try {
      final client = supabaseClient ?? Supabase.instance.client;
      _realtimeChannel = client
          .channel('shifts_realtime_$loungeId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'shifts',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'lounge_id',
              value: loungeId,
            ),
            callback: (payload) {
              debugPrint('⚡ [Realtime] Shift event received: ${payload.eventType}');
              getLiveShiftOverview(loungeId);
              checkActiveShift(loungeId);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'shift_payments',
            callback: (payload) {
              debugPrint('⚡ [Realtime] Shift payment event received: ${payload.eventType}');
              getLiveShiftOverview(loungeId);
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'shift_expenses',
            callback: (payload) {
              debugPrint('⚡ [Realtime] Shift expense event received: ${payload.eventType}');
              getLiveShiftOverview(loungeId);
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('⚠️ [ShiftCubit] Realtime setup error: $e');
    }
  }

  @override
  Future<void> close() {
    _realtimeChannel?.unsubscribe();
    return super.close();
  }

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
            emit(state.copyWith(status: ShiftStatus.initial, activeShift: null));
          }
        },
      );
    } catch (e) {
      emit(state.copyWith(status: ShiftStatus.error, errorMessage: e.toString()));
    }
  }

  /// Combined Open & Verify logic
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
      final openResult = await openShiftUseCase(loungeId, startingCash);
      
      if (isClosed) return;

      await openResult.fold(
        (failure) async {
          emit(state.copyWith(status: ShiftStatus.error, errorMessage: failure.message));
        },
        (_) async {
          debugPrint('🔵 [ShiftCubit] Open success, verifying shift sync...');
          final verifyResult = await getActiveShiftUseCase(loungeId);
          
          if (isClosed) return;

          verifyResult.fold(
            (failure) => emit(state.copyWith(status: ShiftStatus.error, errorMessage: failure.message)),
            (shift) {
              if (shift != null) {
                debugPrint('🟢 [ShiftCubit] Shift verified and synced.');
                emit(state.copyWith(status: ShiftStatus.active, activeShift: shift));
                getLiveShiftOverview(loungeId);
              } else {
                debugPrint('🔴 [ShiftCubit] Shift was created but sync returned null.');
                emit(state.copyWith(
                  status: ShiftStatus.error, 
                  errorMessage: 'Shift created but failed to sync from database.'
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

  /// Quick Open Shift for Manager/Cashier workflow recovery
  Future<bool> quickOpenShift(String loungeId, [double startingCash = 0.0]) async {
    if (isClosed) return false;

    if (loungeId.isEmpty || loungeId == 'null') {
      emit(state.copyWith(
        status: ShiftStatus.error,
        errorMessage: 'Cannot open shift: No Lounge ID assigned.'
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
        (_) async {
          debugPrint('🔵 [ShiftCubit] Quick Open success, verifying active shift...');
          final verifyResult = await getActiveShiftUseCase(loungeId);

          if (isClosed) return false;

          return verifyResult.fold(
            (failure) {
              emit(state.copyWith(status: ShiftStatus.error, errorMessage: failure.message));
              return false;
            },
            (shift) {
              if (shift != null) {
                debugPrint('🟢 [ShiftCubit] Quick shift verified & active.');
                emit(state.copyWith(status: ShiftStatus.active, activeShift: shift));
                getLiveShiftOverview(loungeId);
                return true;
              } else {
                debugPrint('🔴 [ShiftCubit] Quick shift created but verify returned null.');
                emit(state.copyWith(
                  status: ShiftStatus.error,
                  errorMessage: 'Shift created but failed to sync from database.'
                ));
                return false;
              }
            },
          );
        },
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

    final expensesRes = await repository.fetchShiftExpenses(shift.id);
    final paymentsRes = await repository.fetchShiftPayments(shift.id);
    final bookingsRes = await repository.fetchShiftBookings(shift.id);
    final auditLogsRes = await repository.fetchShiftAuditLogs(shift.id);

    if (isClosed) return;

    final expensesList = expensesRes.getOrElse(() => []);
    final paymentsList = paymentsRes.getOrElse(() => []);
    final bookingsList = bookingsRes.getOrElse(() => []);
    final auditLogsList = auditLogsRes.getOrElse(() => []);

    emit(state.copyWith(
      selectedShiftDetails: shift,
      expenses: expensesList,
      payments: paymentsList,
      shiftBookings: bookingsList,
      auditLogs: auditLogsList,
    ));
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
        emit(state.copyWith(
          status: ShiftStatus.error,
          errorMessage: failure.message,
        ));
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
