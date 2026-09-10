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

    // Stage 1: Direct query on profiles table (filtered by lounge_id)
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('lounge_id', cleanLoungeId)
          .neq('role', 'super_admin')
          .order('full_name');

      final list = (response as List)
          .map((json) => StaffModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();

      if (list.isNotEmpty) return list;
    } catch (e1) {
      debugPrint('⚠️ [STAFF_REMOTE_SOURCE] Profiles query failed ($e1), trying lounge_staff join...');
    }

    // Stage 2: Query lounge_staff joined with profiles
    try {
      final response = await _supabase
          .from('lounge_staff')
          .select('*, profiles(id, full_name, email, phone, role, is_active, avatar_url, created_at)')
          .eq('lounge_id', cleanLoungeId);

      if ((response as List).isNotEmpty) {
        return (response as List).map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          final profileMap = map['profiles'] as Map<String, dynamic>?;
          return StaffModel.fromJson({
            'id': map['staff_id'] ?? map['user_id'] ?? profileMap?['id'] ?? map['id'],
            'full_name': profileMap?['full_name'] ?? map['name'] ?? map['full_name'] ?? 'Staff Member',
            'email': profileMap?['email'] ?? map['email'] ?? '',
            'phone': profileMap?['phone'] ?? map['phone'] ?? '',
            'role': map['role'] ?? profileMap?['role'] ?? 'staff',
            'lounge_id': cleanLoungeId,
            'is_active': map['is_active'] ?? profileMap?['is_active'] ?? true,
            'created_at': map['created_at'] ?? profileMap?['created_at'],
          });
        }).toList();
      }
    } catch (e2) {
      debugPrint('⚠️ [STAFF_REMOTE_SOURCE] lounge_staff join query failed ($e2)');
    }

    // Stage 3: Fallback RPC call
    try {
      final response = await _supabase.rpc('get_lounge_staff', params: {
        'p_lounge_id': cleanLoungeId,
      });
      if (response == null) return [];
      return (response as List)
          .map((json) => StaffModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e3) {
      debugPrint('🔴 [STAFF_REMOTE_SOURCE] All staff queries failed: $e3');
      rethrow;
    }
  }

  @override
  Future<void> addStaffMember(AddStaffParams params) async {
    try {
      debugPrint('Adding staff member via create_lounge_staff RPC with params: ${params.toJson()}');
      await _supabase.rpc('create_lounge_staff', params: params.toJson());
      debugPrint('create_lounge_staff RPC executed successfully');
      return;
    } catch (e) {
      debugPrint('create_lounge_staff failed ($e), falling back to add_lounge_staff_member...');
      try {
        await _supabase.rpc('add_lounge_staff_member', params: params.toJson());
        debugPrint('add_lounge_staff_member RPC executed successfully');
        return;
      } catch (e2) {
        debugPrint('Error in staff creation RPC: $e2');
        rethrow;
      }
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
        case 'owner':
          mappedRole = 'owner';
          break;
        case 'manager':
        case 'lounge_admin':
        case 'admin':
          mappedRole = 'manager';
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
