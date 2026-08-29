import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/shift_model.dart';
import '../../models/live_shift_overview_model.dart';

abstract class ShiftRemoteSource {
  Future<List<ShiftModel>> getShifts({String? loungeId});
  Future<ShiftModel?> getActiveShift(String loungeId);
  Future<LiveShiftOverviewModel> getLoungeLiveShiftOverview(String loungeId);
  Future<void> openShift(String loungeId, double startingCash);
  Future<ShiftModel> closeShift(String shiftId, double actualCash, String? notes);
}

class ShiftRemoteSourceImpl implements ShiftRemoteSource {
  final SupabaseClient _supabase;

  ShiftRemoteSourceImpl(this._supabase);

  @override
  Future<List<ShiftModel>> getShifts({String? loungeId}) async {
    var query = _supabase.from('shifts').select('*, profiles(full_name)');
    
    if (loungeId != null) {
      query = query.eq('profiles.lounge_id', loungeId);
    }

    final response = await query.order('start_time', ascending: false);
    return (response as List).map((json) => ShiftModel.fromJson(json)).toList();
  }

  @override
  Future<ShiftModel?> getActiveShift(String loungeId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('🔴 [ShiftRemoteSource] getActiveShift: No authenticated user found.');
        return null;
      }

      debugPrint('🔵 [ShiftRemoteSource] Fetching active shift for user: $userId');
      
      final response = await _supabase
          .from('shifts')
          .select('*, profiles(full_name)')
          .eq('cashier_id', userId)
          .eq('status', 'open')
          .order('start_time', ascending: false)
          .limit(1);
      
      debugPrint('🔵 [ShiftRemoteSource] getActiveShift response list: $response');
      
      if (response == null || (response as List).isEmpty) return null;
      return ShiftModel.fromJson(response.first);
    } catch (e, stack) {
      debugPrint('🔴 [ShiftRemoteSource] Exception in getActiveShift: $e');
      debugPrint('🔴 [ShiftRemoteSource] StackTrace: $stack');
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

      debugPrint('🔵 [ShiftRemoteSource] Opening shift - User: $userId, Lounge: $loungeId, Float: $startingCash');

      await _supabase.from('shifts').insert({
        'cashier_id': userId,
        'lounge_id': loungeId,
        'starting_cash': startingCash,
        'status': 'open',
        'start_time': DateTime.now().toIso8601String(),
      });
      
      debugPrint('🟢 [ShiftRemoteSource] Shift insert successful');
    } catch (e, stack) {
      debugPrint('🔴 [ShiftRemoteSource] Exception in openShift: $e');
      debugPrint('🔴 [ShiftRemoteSource] StackTrace: $stack');
      rethrow;
    }
  }

  @override
  Future<ShiftModel> closeShift(String shiftId, double actualCash, String? notes) async {
    try {
      debugPrint('🔵 [ShiftRemoteSource] Attempting to close shift: $shiftId with cash: $actualCash');
      
      final response = await _supabase.rpc('close_shift_and_calculate_z_report', params: {
        'p_shift_id': shiftId,
        'p_actual_cash': actualCash,
        'p_notes': notes,
      });
      
      debugPrint('🔵 [ShiftRemoteSource] closeShift response: $response');
      
      if (response == null) {
        throw Exception('Server returned no data after closing shift.');
      }

      return ShiftModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e, stack) {
      debugPrint('🔴 [ShiftRemoteSource] Exception in closeShift: $e');
      debugPrint('🔴 [ShiftRemoteSource] StackTrace: $stack');
      rethrow;
    }
  }
}
