import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shift_model.dart';

abstract class ShiftRemoteDataSource {
  Future<ShiftModel?> getCurrentShift(String loungeId);
  Future<void> openShift(String loungeId, double startingCash);
  Future<void> closeShift(String shiftId, double actualCashCounted, String? notes);
  Future<List<ShiftModel>> getShiftHistory({String? loungeId});
}

class ShiftRemoteDataSourceImpl implements ShiftRemoteDataSource {
  final SupabaseClient supabase;

  ShiftRemoteDataSourceImpl(this.supabase);

  @override
  Future<ShiftModel?> getCurrentShift(String loungeId) async {
    final response = await supabase.rpc('get_current_shift', params: {
      'p_lounge_id': loungeId,
    });

    if (response == null) return null;
    return ShiftModel.fromJson(response);
  }

  @override
  Future<void> openShift(String loungeId, double startingCash) async {
    await supabase.rpc('open_shift', params: {
      'p_lounge_id': loungeId,
      'p_starting_cash': startingCash,
    });
  }

  @override
  Future<void> closeShift(String shiftId, double actualCashCounted, String? notes) async {
    await supabase.rpc('close_shift', params: {
      'p_shift_id': shiftId,
      'p_actual_cash_counted': actualCashCounted,
      'p_notes': notes ?? '',
    });
  }

  @override
  Future<List<ShiftModel>> getShiftHistory({String? loungeId}) async {
    var query = supabase.from('shifts').select('*, profiles(full_name)');
    
    if (loungeId != null) {
      query = query.eq('lounge_id', loungeId);
    }
    
    final response = await query.order('start_time', ascending: false);
    return (response as List).map((json) => ShiftModel.fromJson(json)).toList();
  }
}
