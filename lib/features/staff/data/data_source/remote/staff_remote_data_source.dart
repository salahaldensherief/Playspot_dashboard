import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/staff_model.dart';
import '../../models/staff_params.dart';

abstract class StaffRemoteSource {
  Future<List<StaffModel>> getLoungeStaff(String loungeId);
  Future<List<StaffModel>> addStaffMember(AddStaffParams params);
  Future<void> updateStaffMember(String staffId, Map<String, dynamic> data);
  Future<void> updateStaffStatus(String staffId, bool isActive);
  Future<void> deleteStaff(String staffId);
}

class StaffRemoteSourceImpl implements StaffRemoteSource {
  final SupabaseClient _supabase;

  StaffRemoteSourceImpl(this._supabase);

  @override
  Future<List<StaffModel>> getLoungeStaff(String loungeId) async {
    try {
      debugPrint('Fetching staff for loungeId: $loungeId');
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('lounge_id', loungeId)
          .neq('role', 'super_admin')
          .order('full_name');
      
      debugPrint('Staff fetch response: $response');
      return (response as List).map((json) => StaffModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error in getLoungeStaff: $e');
      rethrow;
    }
  }

  @override
  Future<List<StaffModel>> addStaffMember(AddStaffParams params) async {
    try {
      debugPrint('Adding staff member with params: ${params.toJson()}');
      final response = await _supabase.rpc('add_lounge_staff_member', params: params.toJson());
      
      debugPrint('Add staff RPC response: $response');
      if (response == null) return [];
      
      return (response as List).map((json) => StaffModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error in addStaffMember RPC: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateStaffMember(String staffId, Map<String, dynamic> data) async {
    // Map internal params to DB column names if needed
    final updates = {
      if (data.containsKey('name')) 'full_name': data['name'],
      if (data.containsKey('phone')) 'phone': data['phone'],
      if (data.containsKey('role')) 'role': data['role'],
      if (data.containsKey('email')) 'email': data['email'],
    };
    
    await _supabase.from('profiles').update(updates).eq('id', staffId);
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
