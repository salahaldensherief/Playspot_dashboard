import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/shift_model.dart';
import '../../models/shift_params.dart';

abstract class ShiftRemoteSource {
  Future<List<ShiftModel>> getShifts({String? loungeId});
  Future<ShiftModel?> getActiveShift(String cashierId);
  Future<void> openShift(OpenShiftParams params);
  Future<ShiftModel> closeShift(CloseShiftParams params);
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
  Future<ShiftModel?> getActiveShift(String cashierId) async {
    final response = await _supabase
        .from('shifts')
        .select('*, profiles(full_name)')
        .eq('cashier_id', cashierId)
        .eq('status', 'open')
        .maybeSingle();
    
    if (response == null) return null;
    return ShiftModel.fromJson(response);
  }

  @override
  Future<void> openShift(OpenShiftParams params) async {
    await _supabase.from('shifts').insert({
      'cashier_id': params.cashierId,
      'starting_cash': params.startingCash,
      'notes': params.notes,
      'status': 'open',
      'start_time': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<ShiftModel> closeShift(CloseShiftParams params) async {
    final response = await _supabase.rpc('close_shift_and_calculate_z_report', params: params.toJson());
    return ShiftModel.fromJson(response);
  }
}
