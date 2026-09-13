import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shift_model.dart';
import '../models/live_shift_overview_model.dart';
import '../models/shift_expense_model.dart';

abstract class ShiftRemoteDataSource {
  Future<List<ShiftModel>> getShifts({String? loungeId});
  Future<ShiftModel?> getActiveShift(String loungeId);
  Future<LiveShiftOverviewModel> getLoungeLiveShiftOverview(String loungeId);
  Future<void> openShift(String loungeId, double startingCash, {String? notes});
  Future<ShiftModel> closeShift(String shiftId, double actualCash, String? notes, {String? loungeId});
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

      debugPrint('🔵 [ShiftRemoteDataSource] Fetching active shift for user: $userId (loungeId: $loungeId)');

      // 1. Try get_lounge_details RPC first if loungeId is available
      if (loungeId.isNotEmpty) {
        try {
          final detailsResponse = await _supabase.rpc('get_lounge_details', params: {
            'p_lounge_id': loungeId,
          });

          if (detailsResponse != null) {
            Map<String, dynamic> data = {};
            if (detailsResponse is List && detailsResponse.isNotEmpty) {
              data = Map<String, dynamic>.from(detailsResponse.first as Map);
            } else if (detailsResponse is Map) {
              data = Map<String, dynamic>.from(detailsResponse as Map);
            }

            final currentShift = data['current_shift'] ?? data['active_shift'] ?? data['shift'];
            if (currentShift != null && currentShift is Map && currentShift.isNotEmpty) {
              return ShiftModel.fromJson(Map<String, dynamic>.from(currentShift as Map));
            }
          }
        } catch (e) {
          debugPrint('⚠️ [ShiftRemoteDataSource] get_lounge_details RPC failed in getActiveShift ($e), falling back to query');
        }
      }

      // 2. Query shifts table where status = 'open' and closed_at IS NULL
      var query = _supabase
          .from('shifts')
          .select('*, profiles:cashier_id(full_name)')
          .eq('status', 'open')
          .filter('closed_at', 'is', null);

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
  Future<void> openShift(String loungeId, double startingCash, {String? notes}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      debugPrint('🔵 [ShiftRemoteDataSource] Opening shift - User: $userId, Lounge: $loungeId, Float: $startingCash');

      try {
        await _supabase.rpc('open_lounge_shift', params: {
          'p_lounge_id': loungeId,
          'p_starting_cash': startingCash,
          'p_notes': notes,
        });
        debugPrint('🟢 [ShiftRemoteDataSource] RPC open_lounge_shift successful');
      } catch (rpcErr) {
        debugPrint('⚠️ [ShiftRemoteDataSource] RPC open_lounge_shift failed ($rpcErr), trying legacy open_shift');
        try {
          await _supabase.rpc('open_shift', params: {
            'p_lounge_id': loungeId,
            'p_starting_cash': startingCash,
          });
          debugPrint('🟢 [ShiftRemoteDataSource] Legacy RPC open_shift successful');
        } catch (legacyErr) {
          debugPrint('⚠️ [ShiftRemoteDataSource] RPC open_shift failed ($legacyErr), falling back to direct insert');
          await _supabase.from('shifts').insert({
            'cashier_id': userId,
            'lounge_id': loungeId,
            'starting_cash': startingCash,
            'status': 'open',
            'start_time': DateTime.now().toIso8601String(),
          });
        }
      }

      debugPrint('🟢 [ShiftRemoteDataSource] Shift opened successfully');
    } catch (e, stack) {
      debugPrint('🔴 [ShiftRemoteDataSource] Exception in openShift: $e');
      debugPrint('🔴 [ShiftRemoteDataSource] StackTrace: $stack');
      rethrow;
    }
  }

  @override
  Future<ShiftModel> closeShift(String shiftId, double actualCash, String? notes, {String? loungeId}) async {
    try {
      debugPrint('🔵 [ShiftRemoteDataSource] Attempting to close shift: $shiftId (loungeId: $loungeId) with cash: $actualCash');

      if (loungeId != null && loungeId.isNotEmpty) {
        try {
          final response = await _supabase.rpc('close_lounge_shift', params: {
            'p_lounge_id': loungeId,
            'p_actual_cash_counted': actualCash,
            'p_notes': notes,
          });

          debugPrint('🔵 [ShiftRemoteDataSource] close_lounge_shift RPC response: $response');

          if (response != null) {
            Map<String, dynamic> shiftJson = {};
            if (response is List && response.isNotEmpty) {
              shiftJson = Map<String, dynamic>.from(response.first as Map);
            } else if (response is Map) {
              shiftJson = Map<String, dynamic>.from(response as Map);
            }

            if (shiftJson.containsKey('current_shift') && shiftJson['current_shift'] is Map) {
              shiftJson = Map<String, dynamic>.from(shiftJson['current_shift'] as Map);
            } else if (shiftJson.containsKey('shift') && shiftJson['shift'] is Map) {
              shiftJson = Map<String, dynamic>.from(shiftJson['shift'] as Map);
            }

            if (shiftJson.isNotEmpty && shiftJson.containsKey('id')) {
              return ShiftModel.fromJson(shiftJson);
            }
          }
        } catch (rpcErr) {
          debugPrint('⚠️ [ShiftRemoteDataSource] RPC close_lounge_shift failed ($rpcErr), attempting legacy fallback...');
        }
      }

      try {
        final response = await _supabase.rpc('close_shift_and_calculate_z_report', params: {
          'p_shift_id': shiftId,
          'p_actual_cash': actualCash,
          'p_notes': notes,
        });

        debugPrint('🔵 [ShiftRemoteDataSource] close_shift_and_calculate_z_report RPC response: $response');

        if (response != null) {
          return ShiftModel.fromJson(Map<String, dynamic>.from(response));
        }
      } catch (rpcErr) {
        debugPrint('⚠️ [ShiftRemoteDataSource] RPC close_shift_and_calculate_z_report failed ($rpcErr), attempting direct table update fallback...');
      }

      // Direct Table Fallback
      final nowIso = DateTime.now().toIso8601String();

      try {
        final List<dynamic> updatedList = await _supabase
            .from('shifts')
            .update({
              'status': 'closed',
              'actual_cash_counted': actualCash,
              'end_time': nowIso,
              'closed_at': nowIso,
              if (notes != null && notes.isNotEmpty) 'notes': notes,
            })
            .eq('id', shiftId)
            .select('*, profiles:cashier_id(full_name)');

        if (updatedList.isNotEmpty) {
          debugPrint('🟢 [ShiftRemoteDataSource] Direct table update closeShift successful!');
          return ShiftModel.fromJson(Map<String, dynamic>.from(updatedList.first));
        }
      } catch (e1) {
        debugPrint('⚠️ [ShiftRemoteDataSource] First update attempt failed ($e1), trying simpler fallback...');
        try {
          final List<dynamic> updatedList = await _supabase
              .from('shifts')
              .update({
                'status': 'closed',
                if (notes != null && notes.isNotEmpty) 'notes': notes,
              })
              .eq('id', shiftId)
              .select('*, profiles:cashier_id(full_name)');

          if (updatedList.isNotEmpty) {
            debugPrint('🟢 [ShiftRemoteDataSource] Simple table update closeShift successful!');
            return ShiftModel.fromJson(Map<String, dynamic>.from(updatedList.first));
          }
        } catch (e2) {
          debugPrint('⚠️ [ShiftRemoteDataSource] Simple table update failed: $e2');
        }
      }

      throw Exception('فشل تقفيل الشيفت: يرجى التأكد من صلاحيات قاعدة البيانات');
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
    final rawId = payload['id']?.toString() ?? '';
    if (rawId.length != 36 || !rawId.contains('-')) {
      payload.remove('id');
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
