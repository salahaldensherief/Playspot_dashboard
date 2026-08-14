import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/staff_model.dart';
import '../../models/staff_params.dart';

abstract class StaffRemoteSource {
  Future<List<StaffModel>> getLoungeStaff(String loungeId);
  Future<List<StaffModel>> addStaffMember(AddStaffParams params);
  Future<void> updateStaffStatus(String staffId, bool isActive);
  Future<void> deleteStaff(String staffId);
}

class StaffRemoteSourceImpl implements StaffRemoteSource {
  final SupabaseClient _supabase;

  StaffRemoteSourceImpl(this._supabase);

  @override
  Future<List<StaffModel>> getLoungeStaff(String loungeId) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('lounge_id', loungeId)
        .neq('role', 'super_admin')
        .order('full_name');
    
    return (response as List).map((json) => StaffModel.fromJson(json)).toList();
  }

  @override
  Future<List<StaffModel>> addStaffMember(AddStaffParams params) async {
    final response = await _supabase.rpc('add_lounge_staff_member', params: params.toJson());
    
    if (response == null) return [];
    
    return (response as List).map((json) => StaffModel.fromJson(json)).toList();
  }

  @override
  Future<void> updateStaffStatus(String staffId, bool isActive) async {
    await _supabase.from('profiles').update({'is_active': isActive}).eq('id', staffId);
  }

  @override
  Future<void> deleteStaff(String staffId) async {
    await _supabase.from('profiles').delete().eq('id', staffId);
  }
}
