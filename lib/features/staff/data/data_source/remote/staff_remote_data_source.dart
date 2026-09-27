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

    AppLogger.info('Adding staff member via create_lounge_staff RPC');
    await _supabase.rpc(
      'create_lounge_staff',
      params: params.toJson(),
    );
    AppLogger.info('create_lounge_staff RPC executed successfully');
  }

  @override
  Future<void> updateStaffMember(
    String staffId,
    Map<String, dynamic> data,
  ) async {
    final cleanStaffId = staffId.trim();
    if (cleanStaffId.isEmpty) {
      throw ArgumentError('Staff ID cannot be empty');
    }

    String? mappedRole;
    if (data['role'] != null) {
      final rawRole = data['role'].toString().toLowerCase().trim();
      mappedRole = switch (rawRole) {
        'cashier' || 'role_cashier' => 'cashier',
        'manager' || 'lounge_admin' || 'admin' => 'manager',
        'staff' || 'role_staff' => 'staff',
        _ => rawRole,
      };
    }

    await _supabase.rpc(
      'update_lounge_staff_member',
      params: {
        'p_target_user_id': cleanStaffId,
        'p_full_name': data['name']?.toString(),
        'p_phone': data['phone']?.toString(),
        'p_role': mappedRole,
      },
    );
  }

  @override
  Future<void> updateStaffStatus(
    String staffId,
    bool isActive,
  ) async {
    final cleanStaffId = staffId.trim();
    if (cleanStaffId.isEmpty) return;

    await _supabase.rpc(
      'set_lounge_staff_active',
      params: {
        'p_target_user_id': cleanStaffId,
        'p_is_active': isActive,
      },
    );
  }

  @override
  Future<void> deleteStaff(String staffId) async {
    final cleanStaffId = staffId.trim();
    if (cleanStaffId.isEmpty) return;

    await _supabase.rpc(
      'remove_lounge_staff_member',
      params: {
        'p_target_user_id': cleanStaffId,
      },
    );
  }

}
