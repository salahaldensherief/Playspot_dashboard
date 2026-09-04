import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/staff_model.dart';
import '../../models/staff_params.dart';

abstract class StaffRemoteSource {
  Future<List<StaffModel>> getLoungeStaff(String loungeId);
  Future<void> addStaffMember(AddStaffParams params);
  Future<void> updateStaffMember(String staffId, Map<String, dynamic> data);
  Future<void> updateStaffStatus(String staffId, bool isActive);
  Future<void> deleteStaff(String staffId);
}

class StaffRemoteSourceImpl implements StaffRemoteSource {
  final SupabaseClient _supabase;

  StaffRemoteSourceImpl(this._supabase);

  @override
  Future<List<StaffModel>> getLoungeStaff(String loungeId) async {
    final cleanLoungeId = loungeId.trim();
    if (cleanLoungeId.isEmpty) return [];

    try {
      debugPrint('Fetching staff for loungeId via RPC: $cleanLoungeId');
      
      final response = await _supabase.rpc('get_lounge_staff', params: {
        'p_lounge_id': cleanLoungeId,
      });
      
      debugPrint('Staff RPC response: $response');
      if (response == null) return [];
      
      return (response as List).map((json) => StaffModel.fromJson(Map<String, dynamic>.from(json))).toList();
    } catch (e) {
      debugPrint('Error in getLoungeStaff RPC: $e');
      try {
        final response = await _supabase
            .from('profiles')
            .select()
            .eq('lounge_id', cleanLoungeId)
            .neq('role', 'super_admin')
            .order('full_name');
        return (response as List).map((json) => StaffModel.fromJson(Map<String, dynamic>.from(json))).toList();
      } catch (e2) {
        rethrow;
      }
    }
  }

  @override
  Future<void> addStaffMember(AddStaffParams params) async {
    try {
      debugPrint('Adding staff member with params: ${params.toJson()}');
      await _supabase.rpc('add_staff_member', params: params.toJson());
      debugPrint('Add staff RPC executed successfully');
      return;
    } catch (e) {
      debugPrint('Error in addStaffMember RPC: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateStaffMember(String staffId, Map<String, dynamic> data) async {
    final cleanStaffId = staffId.trim();
    if (cleanStaffId.isEmpty) {
      throw Exception('Staff ID cannot be empty');
    }

    String? mappedRole;
    if (data.containsKey('role') && data['role'] != null) {
      final rawRole = data['role'].toString().toLowerCase().trim();
      switch (rawRole) {
        case 'cashier':
        case 'role_cashier':
          mappedRole = 'cashier';
          break;
        case 'lounge_owner':
        case 'manager':
        case 'lounge_admin':
          mappedRole = 'lounge_owner';
          break;
        case 'staff':
        case 'role_staff':
          mappedRole = 'staff';
          break;
        default:
          mappedRole = rawRole;
      }
    }

    final updates = <String, dynamic>{
      if (data.containsKey('name') && data['name'] != null) 'full_name': data['name'],
      if (data.containsKey('phone') && data['phone'] != null) 'phone': data['phone'],
      if (mappedRole != null) 'role': mappedRole,
      if (data.containsKey('email') && data['email'] != null) 'email': data['email'],
      if (data.containsKey('national_id_number') && data['national_id_number'] != null) 'national_id_number': data['national_id_number'],
      if (data.containsKey('id_front_url') && data['id_front_url'] != null) 'id_front_url': data['id_front_url'],
      if (data.containsKey('id_back_url') && data['id_back_url'] != null) 'id_back_url': data['id_back_url'],
    };

    debugPrint('🔵 [STAFF_REMOTE_SOURCE] Updating profile targeting ID: $cleanStaffId with updates: $updates');

    try {
      await _supabase.from('profiles').update(updates).eq('id', cleanStaffId);
      debugPrint('🟢 [STAFF_REMOTE_SOURCE] Profile updated successfully for $cleanStaffId');
    } catch (e) {
      debugPrint('🔴 [STAFF_REMOTE_SOURCE] Failed to update profile $cleanStaffId: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateStaffStatus(String staffId, bool isActive) async {
    final cleanStaffId = staffId.trim();
    if (cleanStaffId.isEmpty) return;
    await _supabase.from('profiles').update({'is_active': isActive}).eq('id', cleanStaffId);
  }

  @override
  Future<void> deleteStaff(String staffId) async {
    final cleanStaffId = staffId.trim();
    if (cleanStaffId.isEmpty) return;
    await _supabase.from('profiles').delete().eq('id', cleanStaffId);
  }
}
