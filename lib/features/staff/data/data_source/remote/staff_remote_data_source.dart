import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import 'package:play_spot_dashboard/features/auth/data/models/user_model.dart';
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

    final Map<String, StaffModel> staffMap = {};

    // 1. Try RPC get_lounge_staff first (most efficient, single RPC)
    try {
      final response = await _supabase.rpc(
        'get_lounge_staff',
        params: {'p_lounge_id': cleanLoungeId},
      );
      if (response != null && response is List && response.isNotEmpty) {
        for (final item in response) {
          final model = StaffModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
          if (model.id.isNotEmpty) {
            staffMap[model.id] = model;
          }
        }
        if (staffMap.isNotEmpty) {
          AppLogger.info('Fetched ${staffMap.length} staff members via get_lounge_staff RPC');
          return staffMap.values.toList();
        }
      }
    } catch (e) {
      AppLogger.warning('RPC get_lounge_staff error ($e)');
    }

    // 2. Fallback: Query lounge_staff joined with profiles
    try {
      final response = await _supabase
          .from('lounge_staff')
          .select(
            '*, profiles(id, full_name, email, phone, role, is_active, avatar_url, created_at)',
          )
          .eq('lounge_id', cleanLoungeId);

      for (final dynamic item in (response as List)) {
        final map = Map<String, dynamic>.from(item as Map);
        final profileMap = map['profiles'] as Map<String, dynamic>?;
        final id = (map['staff_id'] ??
                map['user_id'] ??
                profileMap?['id'] ??
                map['id'])
            ?.toString() ??
            '';
        if (id.isNotEmpty && !staffMap.containsKey(id)) {
          final model = StaffModel.fromJson({
            'id': id,
            'full_name': profileMap?['full_name'] ??
                map['name'] ??
                map['full_name'] ??
                'Staff Member',
            'email': profileMap?['email'] ?? map['email'] ?? '',
            'phone': profileMap?['phone'] ?? map['phone'] ?? '',
            'role': map['role'] ?? profileMap?['role'] ?? 'staff',
            'lounge_id': cleanLoungeId,
            'is_active': map['is_active'] ?? profileMap?['is_active'] ?? true,
            'created_at': map['created_at'] ?? profileMap?['created_at'],
          });
          staffMap[id] = model;
        }
      }
    } catch (e) {
      AppLogger.warning('lounge_staff join query error ($e)');
    }

    // 3. Fallback: Direct query on profiles table (only if still empty)
    if (staffMap.isEmpty) {
      try {
        final response = await _supabase
            .from('profiles')
            .select()
            .eq('lounge_id', cleanLoungeId)
            .neq('role', 'super_admin')
            .order('full_name');

        for (final dynamic item in (response as List)) {
          final model = StaffModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
          if (model.id.isNotEmpty && !staffMap.containsKey(model.id)) {
            staffMap[model.id] = model;
          }
        }
      } catch (e) {
        AppLogger.warning('profiles query error ($e)');
      }
    }

    AppLogger.info('getLoungeStaff fetched ${staffMap.length} staff members');
    return staffMap.values.toList();
  }

  @override
  Future<void> addStaffMember(AddStaffParams params) async {
    final roleClean = params.role.trim().toLowerCase();
    if (roleClean == 'super_admin' || roleClean == 'system_admin') {
      throw Exception(
        'غير مسموح بإنشاء حساب super_admin من واجهة إدارة طاقم العمل.',
      );
    }

    try {
      AppLogger.info('Adding staff member via create_lounge_staff RPC with params: ${params.toJson()}');
      await _supabase.rpc('create_lounge_staff', params: params.toJson());
      AppLogger.info('create_lounge_staff RPC executed successfully');
      return;
    } catch (e) {
      AppLogger.warning('create_lounge_staff failed ($e), falling back to add_lounge_staff_member...');
      try {
        await _supabase.rpc('add_lounge_staff_member', params: params.toJson());
        AppLogger.info('add_lounge_staff_member RPC executed successfully');
        return;
      } catch (e2) {
        AppLogger.error('Error in staff creation RPC: $e2');
        rethrow;
      }
    }
  }

  @override
  Future<void> updateStaffMember(
    String staffId,
    Map<String, dynamic> data,
  ) async {
    final cleanStaffId = staffId.trim();
    if (cleanStaffId.isEmpty) {
      throw Exception('Staff ID cannot be empty');
    }

    String? mappedRole;
    if (data.containsKey('role') && data['role'] != null) {
      final rawRole = data['role'].toString().toLowerCase().trim();
      if (rawRole == 'super_admin' || rawRole == 'system_admin') {
        throw Exception(
          'غير مسموح برفع الحساب إلى super_admin من هذه الواجهة.',
        );
      }
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
      if (data.containsKey('name') && data['name'] != null)
        'full_name': data['name'],
      if (data.containsKey('phone') && data['phone'] != null)
        'phone': data['phone'],
      'role': ?mappedRole,
      if (data.containsKey('email') && data['email'] != null)
        'email': data['email'],
      if (data.containsKey('national_id_number') &&
          data['national_id_number'] != null)
        'national_id_number': data['national_id_number'],
      if (data.containsKey('id_front_url') && data['id_front_url'] != null)
        'id_front_url': data['id_front_url'],
      if (data.containsKey('id_back_url') && data['id_back_url'] != null)
        'id_back_url': data['id_back_url'],
      if (data.containsKey('city_id')) 'city_id': data['city_id'],
    };

    final cleanUpdates = UserModel.sanitizeProfilePayload(updates);

    AppLogger.info('Updating profile targeting ID: $cleanStaffId with updates: $cleanUpdates');

    try {
      if (cleanUpdates.isNotEmpty) {
        await _supabase
            .from('profiles')
            .update(cleanUpdates)
            .eq('id', cleanStaffId);
        AppLogger.info('Profile updated successfully for $cleanStaffId');
      }
    } catch (e) {
      AppLogger.error('Failed to update profile $cleanStaffId: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateStaffStatus(String staffId, bool isActive) async {
    final cleanStaffId = staffId.trim();
    if (cleanStaffId.isEmpty) return;
    await _supabase
        .from('profiles')
        .update({'is_active': isActive})
        .eq('id', cleanStaffId)
        .neq('role', 'super_admin');
  }

  @override
  Future<void> deleteStaff(String staffId) async {
    final cleanStaffId = staffId.trim();
    if (cleanStaffId.isEmpty) return;

    // Rule: Never allow deleting super_admin or modifying system roles from UI
    try {
      final targetProfile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', cleanStaffId)
          .maybeSingle();

      if (targetProfile != null &&
          (targetProfile['role'] == 'super_admin' ||
              targetProfile['role'] == 'system_admin')) {
        throw Exception('غير مسموح بحذف أو تعديل صلاحيات حساب super_admin.');
      }
    } catch (e) {
      if (e.toString().contains('super_admin')) rethrow;
    }

    // 1. Delete staff record from lounge_staff
    try {
      await _supabase
          .from('lounge_staff')
          .delete()
          .or('id.eq.$cleanStaffId,user_id.eq.$cleanStaffId');
    } catch (e) {
      AppLogger.warning('lounge_staff deletion failed ($e)');
    }

    // 2. Deactivate profile instead of hard profile deletion
    try {
      await _supabase
          .from('profiles')
          .update({'is_active': false})
          .eq('id', cleanStaffId)
          .neq('role', 'super_admin');
    } catch (e) {
      AppLogger.warning('profile deactivation failed ($e)');
    }
  }
}
