import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shift_model.dart';
import '../models/live_shift_overview_model.dart';
import '../models/shift_expense_model.dart';

abstract class ShiftRemoteDataSource {
  Future<List<ShiftModel>> getShifts({String? loungeId});
  Future<ShiftModel?> getActiveShift(String loungeId);
  Future<LiveShiftOverviewModel> getLoungeLiveShiftOverview(String loungeId);
  Future<void> openShift(String loungeId, double startingCash);
  Future<ShiftModel> closeShift(String shiftId, double actualCash, String? notes);
  Future<void> approveShift(String shiftId, String managerId, String? notes);
  Future<void> addShiftExpense(ShiftExpenseModel expense);
  Future<List<ShiftExpenseModel>> fetchShiftExpenses(String shiftId);
}

class ShiftRemoteDataSourceImpl implements ShiftRemoteDataSource {
  final SupabaseClient _supabase;

  ShiftRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<ShiftModel>> getShifts({String? loungeId}) async {
    // Fetch shifts with cashier name from profiles table
    var query = _supabase.from('shifts').select('*, profiles:cashier_id(full_name)');
    
    if (loungeId != null) {
      query = query.eq('lounge_id', loungeId);
    }

    final response = await query.order('start_time', ascending: false);
    return (response as List).map((json) => ShiftModel.fromJson(json)).toList();
  }

  @override
  Future<ShiftModel?> getActiveShift(String loungeId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('🔴 [ShiftRemoteDataSource] getActiveShift: No authenticated user found.');
        return null;
      }

      debugPrint('🔵 [ShiftRemoteDataSource] Fetching active shift for user: $userId');

      // Fetch active shift with cashier name from profiles
      final response = await _supabase
          .from('shifts')
          .select('*, profiles:cashier_id(full_name)')
          .eq('cashier_id', userId)
          .eq('status', 'open')
          .order('start_time', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return ShiftModel.fromJson(response);
    } catch (e, stack) {
      debugPrint('🔴 [ShiftRemoteDataSource] Exception in getActiveShift: $e');
      debugPrint('🔴 [ShiftRemoteDataSource] StackTrace: $stack');
      rethrow;
    }
  }

  @override
  Future<LiveShiftOverviewModel> getLoungeLiveShiftOverview(String loungeId) async {
    final response = await _supabase.rpc('get_lounge_live_shift_overview', params: {
      'p_lounge_id': loungeId,
    });
    return LiveShiftOverviewModel.fromJson(response);
  }

  @override
  Future<void> openShift(String loungeId, double startingCash) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      debugPrint('🔵 [ShiftRemoteDataSource] Opening shift - User: $userId, Lounge: $loungeId, Float: $startingCash');

      await _supabase.from('shifts').insert({
        'cashier_id': userId,
        'lounge_id': loungeId,
        'starting_cash': startingCash,
        'status': 'open',
        'start_time': DateTime.now().toIso8601String(),
      });

      debugPrint('🟢 [ShiftRemoteDataSource] Shift insert successful');
    } catch (e, stack) {
      debugPrint('🔴 [ShiftRemoteDataSource] Exception in openShift: $e');
      debugPrint('🔴 [ShiftRemoteDataSource] StackTrace: $stack');
      rethrow;
    }
  }

  @override
  Future<ShiftModel> closeShift(String shiftId, double actualCash, String? notes) async {
    try {
      debugPrint('🔵 [ShiftRemoteDataSource] Attempting to close shift: $shiftId with cash: $actualCash');

      final response = await _supabase.rpc('close_shift_and_calculate_z_report', params: {
        'p_shift_id': shiftId,
        'p_actual_cash': actualCash,
        'p_notes': notes,
      });

      debugPrint('🔵 [ShiftRemoteDataSource] closeShift response: $response');

      if (response == null) {
        throw Exception('Server returned no data after closing shift.');
      }

      return ShiftModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e, stack) {
      debugPrint('🔴 [ShiftRemoteDataSource] Exception in closeShift: $e');
      debugPrint('🔴 [ShiftRemoteDataSource] StackTrace: $stack');
      rethrow;
    }
  }

  @override
  Future<void> approveShift(String shiftId, String managerId, String? notes) async {
    await _supabase.rpc('approve_shift', params: {
      'p_shift_id': shiftId,
      'p_manager_id': managerId,
      'p_notes': notes,
    });
  }

  @override
  Future<void> addShiftExpense(ShiftExpenseModel expense) async {
    final userId = _supabase.auth.currentUser?.id;
    final payload = expense.toJson();
    if (userId != null) {
      payload['created_by'] = userId;
    }
    debugPrint('🔵 [ShiftRemoteDataSource] Inserting shift expense: $payload');
    await _supabase.from('shift_expenses').insert(payload);
    debugPrint('🟢 [ShiftRemoteDataSource] Inserted shift expense successfully');
  }

  @override
  Future<List<ShiftExpenseModel>> fetchShiftExpenses(String shiftId) async {
    debugPrint('🔵 [ShiftRemoteDataSource] Fetching shift expenses for shiftId: $shiftId');
    final response = await _supabase
        .from('shift_expenses')
        .select('*, profiles:created_by(full_name)')
        .eq('shift_id', shiftId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ShiftExpenseModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }
}
