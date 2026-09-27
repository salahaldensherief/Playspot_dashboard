import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cashier_performance_model.dart';
import '../models/live_shift_overview_model.dart';
import '../models/lounge_comparison_model.dart';
import '../models/shift_audit_log_model.dart';
import '../models/shift_expense_model.dart';
import '../models/shift_model.dart';
import '../models/shift_payment_model.dart';
import 'shift_details_remote_helper.dart';
import 'shift_remote_data_source.dart';
import 'shift_reporting_remote_helper.dart';

class ShiftRemoteDataSourceImpl implements ShiftRemoteDataSource {
  final SupabaseClient _supabase;
  late final ShiftReportingRemoteHelper _reportingHelper;
  late final ShiftDetailsRemoteHelper _detailsHelper;

  ShiftRemoteDataSourceImpl(this._supabase) {
    _reportingHelper = ShiftReportingRemoteHelper(_supabase);
    _detailsHelper = ShiftDetailsRemoteHelper(_supabase);
  }

  @override
  Future<List<ShiftModel>> getShifts({
    String? loungeId,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _supabase
        .from('shifts')
        .select('*, profiles:cashier_id(full_name)');

    if (loungeId != null && loungeId.isNotEmpty) {
      query = query.eq('lounge_id', loungeId);
    }

    final response = await query
        .order('start_time', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List).map((json) => ShiftModel.fromJson(json)).toList();
  }

  @override
  Future<List<ShiftModel>> getShiftReport({
    String? loungeId,
    DateTime? startDate,
    DateTime? endDate,
    String? cashierId,
  }) => _reportingHelper.getShiftReport(
    loungeId: loungeId,
    startDate: startDate,
    endDate: endDate,
    cashierId: cashierId,
    fallbackFetcher: getShifts,
  );

  @override
  Future<List<CashierPerformanceModel>> getCashierPerformance({
    String? loungeId,
    DateTime? startDate,
    DateTime? endDate,
  }) => _reportingHelper.getCashierPerformance(
    loungeId: loungeId,
    startDate: startDate,
    endDate: endDate,
  );

  @override
  Future<List<LoungeComparisonModel>> getLoungeComparison({
    DateTime? startDate,
    DateTime? endDate,
  }) => _reportingHelper.getLoungeComparison(
    startDate: startDate,
    endDate: endDate,
  );

  @override
  Future<ShiftModel?> getActiveShift(String loungeId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint(
          '🔴 [ShiftRemoteDataSource] getActiveShift: No authenticated user found.',
        );
        return null;
      }

      var query = _supabase
          .from('shifts')
          .select('*, profiles:cashier_id(full_name)')
          .or('status.eq.open,closed_at.is.null');

      if (loungeId.isNotEmpty) {
        query = query.eq('lounge_id', loungeId);
      } else {
        query = query.eq('cashier_id', userId);
      }

      final response = await query
          .order('start_time', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      var model = ShiftModel.fromJson(response);

      if ((model.cashierName == null ||
              model.cashierName == 'N/A' ||
              model.cashierName!.trim().isEmpty) &&
          model.cashierId.isNotEmpty) {
        try {
          final profileRes = await _supabase
              .from('profiles')
              .select('full_name')
              .eq('id', model.cashierId)
              .maybeSingle();

          if (profileRes != null && profileRes['full_name'] != null) {
            final name = profileRes['full_name'].toString().trim();
            if (name.isNotEmpty) {
              model = ShiftModel(
                id: model.id,
                loungeId: model.loungeId,
                cashierId: model.cashierId,
                cashierName: name,
                startingCash: model.startingCash,
                cashRevenue: model.cashRevenue,
                digitalRevenue: model.digitalRevenue,
                expensesTotal: model.expensesTotal,
                cashDropsTotal: model.cashDropsTotal,
                expectedCash: model.expectedCash,
                actualCash: model.actualCash,
                discrepancy: model.discrepancy,
                status: model.status,
                startTime: model.startTime,
                endTime: model.endTime,
                notes: model.notes,
                isApproved: model.isApproved,
                approvedBy: model.approvedBy,
                approvedAt: model.approvedAt,
                managerNotes: model.managerNotes,
              );
            }
          }
        } catch (profileErr) {
          debugPrint(
            '⚠️ [ShiftRemoteDataSource] Cashier name profile lookup failed: $profileErr',
          );
        }
      }

      return model;
    } catch (e, stack) {
      debugPrint('🔴 [ShiftRemoteDataSource] Exception in getActiveShift: $e');
      debugPrint('🔴 [ShiftRemoteDataSource] StackTrace: $stack');
      rethrow;
    }
  }

  @override
  Future<LiveShiftOverviewModel> getLoungeLiveShiftOverview(
    String loungeId,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_lounge_live_shift_overview',
        params: {'p_lounge_id': loungeId},
      );
      if (response != null) {
        final jsonMap = Map<String, dynamic>.from(
          response is List && response.isNotEmpty
              ? response.first as Map
              : response as Map,
        );
        var overview = LiveShiftOverviewModel.fromJson(jsonMap);

        if (!overview.hasActiveShift) {
          try {
            final activeShift = await getActiveShift(loungeId);
            if (activeShift != null) {
              return LiveShiftOverviewModel(
                hasActiveShift: true,
                shiftId: activeShift.id,
                cashierName: activeShift.cashierName ?? 'الكاشير الحالي',
                cashierAvatar: null,
                cashierPhone: null,
                startTime: activeShift.startTime,
                startingCash: activeShift.startingCash,
                cashInDrawer:
                    activeShift.startingCash +
                    (activeShift.cashRevenue ?? 0.0) -
                    (activeShift.expensesTotal ?? 0.0),
                digitalPayments: activeShift.digitalRevenue ?? 0.0,
                activeSessions: 0,
                closedBookings: 0,
              );
            }
          } catch (e) {
            debugPrint(
              '⚠️ [ShiftRemoteDataSource] Fallback active shift lookup error: $e',
            );
          }
        } else if (overview.hasActiveShift &&
            (overview.cashierName == null ||
                overview.cashierName == 'N/A' ||
                overview.cashierName!.trim().isEmpty)) {
          try {
            final activeShift = await getActiveShift(loungeId);
            if (activeShift != null && activeShift.cashierName != 'N/A') {
              overview = LiveShiftOverviewModel(
                hasActiveShift: overview.hasActiveShift,
                shiftId: overview.shiftId ?? activeShift.id,
                cashierName: activeShift.cashierName,
                cashierAvatar: overview.cashierAvatar,
                cashierPhone: overview.cashierPhone,
                startTime: overview.startTime ?? activeShift.startTime,
                startingCash: overview.startingCash ?? activeShift.startingCash,
                cashInDrawer: overview.cashInDrawer,
                digitalPayments: overview.digitalPayments,
                activeSessions: overview.activeSessions,
                closedBookings: overview.closedBookings,
              );
            }
          } catch (e) {
            debugPrint(
              '⚠️ [ShiftRemoteDataSource] Cashier name overview resolution error: $e',
            );
          }
        }

        return overview;
      }
    } catch (e) {
      debugPrint(
        '⚠️ [ShiftRemoteDataSource] RPC get_lounge_live_shift_overview error ($e)',
      );
    }

    try {
      final activeShift = await getActiveShift(loungeId);
      if (activeShift != null) {
        return LiveShiftOverviewModel(
          hasActiveShift: true,
          shiftId: activeShift.id,
          cashierName: activeShift.cashierName ?? 'الكاشير الحالي',
          cashierAvatar: null,
          cashierPhone: null,
          startTime: activeShift.startTime,
          startingCash: activeShift.startingCash,
          cashInDrawer:
              activeShift.startingCash +
              (activeShift.cashRevenue ?? 0.0) -
              (activeShift.expensesTotal ?? 0.0),
          digitalPayments: activeShift.digitalRevenue ?? 0.0,
          activeSessions: 0,
          closedBookings: 0,
        );
      }
    } catch (_) {}

    return LiveShiftOverviewModel(
      hasActiveShift: false,
      shiftId: null,
      cashierName: null,
      cashierAvatar: null,
      cashierPhone: null,
      startTime: null,
      startingCash: 0.0,
      cashInDrawer: 0.0,
      digitalPayments: 0.0,
      activeSessions: 0,
      closedBookings: 0,
    );
  }

  @override
  Future<void> openShift(
    String loungeId,
    double startingCash, {
    String? notes,
  }) async {
    await _supabase.rpc(
      'open_lounge_shift',
      params: {
        'p_lounge_id': loungeId,
        'p_starting_cash': startingCash,
        'p_notes': notes,
      },
    );
  }

  @override
  Future<ShiftModel> closeShift(
    String shiftId,
    double actualCash,
    String? notes, {
    String? loungeId,
  }) async {
    final cashierId = _supabase.auth.currentUser?.id;
    if (cashierId == null || cashierId.isEmpty) {
      throw Exception('User not authenticated');
    }

    final response = await _supabase.rpc(
      'blind_close_shift',
      params: {
        'p_shift_id': shiftId,
        'p_cashier_id': cashierId,
        'p_counted_cash': actualCash,
        'p_notes': notes,
      },
    );

    if (response is Map) {
      final map = Map<String, dynamic>.from(response);
      final refreshed = await _supabase
          .from('shifts')
          .select('*, profiles:cashier_id(full_name)')
          .eq('id', shiftId)
          .maybeSingle();

      if (refreshed != null) {
        return ShiftModel.fromJson(refreshed);
      }

      return ShiftModel.fromJson(map);
    }

    throw Exception('Invalid close shift response');
  }

  @override
  Future<void> approveShift(
    String shiftId,
    String managerId,
    String? notes,
  ) async {
    await _supabase.rpc(
      'approve_shift',
      params: {
        'p_shift_id': shiftId,
        'p_manager_id': managerId,
        'p_notes': notes,
      },
    );
  }

  @override
  Future<void> addShiftExpense(ShiftExpenseModel expense) =>
      _detailsHelper.addShiftExpense(expense);

  @override
  Future<List<ShiftExpenseModel>> fetchShiftExpenses(String shiftId) =>
      _detailsHelper.fetchShiftExpenses(shiftId);

  @override
  Future<List<ShiftPaymentModel>> fetchShiftPayments(String shiftId) =>
      _detailsHelper.fetchShiftPayments(shiftId);

  @override
  Future<List<Map<String, dynamic>>> fetchShiftBookings(String shiftId) =>
      _detailsHelper.fetchShiftBookings(shiftId);

  @override
  Future<List<ShiftAuditLogModel>> fetchShiftAuditLogs(String shiftId) =>
      _detailsHelper.fetchShiftAuditLogs(shiftId);
}
