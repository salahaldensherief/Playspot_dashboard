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
          .eq('status', 'open')
          .isFilter('closed_at', null);

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
    final response = await _supabase.rpc(
      'get_lounge_live_shift_overview',
      params: {'p_lounge_id': loungeId},
    );
    final raw = response is List && response.length == 1
        ? response.single
        : response;
    if (raw is! Map || raw['has_active_shift'] is! bool) {
      throw const FormatException('Invalid live shift overview response');
    }
    // The RPC owns authorization, shift state and financial aggregates.
    // A denial or unavailable contract must remain an error, never "no shift".
    return LiveShiftOverviewModel.fromJson(Map<String, dynamic>.from(raw));
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
    final actorId = _supabase.auth.currentUser?.id;
    if (actorId == null || actorId.isEmpty) {
      throw const PostgrestException(
        message: 'Authentication required',
        code: '28000',
      );
    }
    if (loungeId == null || loungeId.trim().isEmpty) {
      throw ArgumentError('Closing a shift requires lounge scope');
    }
    final shift = await _supabase
        .from('shifts')
        .select('id,lounge_id,cashier_id,starting_cash,start_time')
        .eq('id', shiftId)
        .eq('lounge_id', loungeId)
        .single();
    final cashierId = shift['cashier_id'];
    if (cashierId is! String || cashierId.isEmpty) {
      throw const FormatException('Shift cashier identity is missing');
    }
    // The RPC validates the actor independently against this stored cashier.
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
      if (map['success'] != true ||
          map['shift_id'] != shiftId ||
          map['status'] != 'closed') {
        throw const FormatException('Unconfirmed shift closure');
      }
      final refreshed = await _supabase
          .from('shifts')
          .select('*, profiles:cashier_id(full_name)')
          .eq('id', shiftId)
          .eq('lounge_id', loungeId)
          .maybeSingle();

      if (refreshed != null) {
        return ShiftModel.fromJson(refreshed);
      }

      return ShiftModel.fromJson({...shift, ...map});
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
