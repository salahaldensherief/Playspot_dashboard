import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/permission_item_model.dart';

abstract class PermissionsRemoteSource {
  Future<List<PermissionItemModel>> getRolePermissions(String role);
  Future<void> updateRolePermission(String role, String permissionKey, bool isEnabled);
}

class PermissionsRemoteSourceImpl implements PermissionsRemoteSource {
  final SupabaseClient _supabase;

  PermissionsRemoteSourceImpl(this._supabase);

  @override
  Future<List<PermissionItemModel>> getRolePermissions(String role) async {
    final cleanRole = role.toLowerCase().trim();
    try {
      final response = await _supabase.rpc('get_role_permissions', params: {
        'p_role': cleanRole,
      });
      if (response != null && response is List && response.isNotEmpty) {
        return response
            .map((json) => PermissionItemModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
    } catch (e) {
      // ignore: avoid_print
      print('PermissionsRemoteSource: RPC get_role_permissions failed: $e');
    }

    // Fallback: Query role_permissions table directly
    try {
      final tableResponse = await _supabase
          .from('role_permissions')
          .select('*, permissions(*)')
          .eq('role', cleanRole);
      if (tableResponse.isNotEmpty) {
        return tableResponse.map((json) {
          final perm = json['permissions'] as Map<String, dynamic>? ?? {};
          return PermissionItemModel(
            key: json['permission_key']?.toString() ?? perm['key']?.toString() ?? '',
            nameAr: perm['name_ar']?.toString() ?? json['permission_key']?.toString() ?? '',
            nameEn: perm['name_en']?.toString() ?? json['permission_key']?.toString() ?? '',
            category: perm['category']?.toString() ?? 'General',
            descriptionAr: perm['description_ar']?.toString() ?? '',
            descriptionEn: perm['description_en']?.toString() ?? '',
            isEnabled: json['is_enabled'] ?? false,
          );
        }).toList();
      }
    } catch (tableError) {
      // ignore: avoid_print
      print('PermissionsRemoteSource: Fallback table select failed: $tableError');
    }

    // Default static permissions list fallback so UI is NEVER EMPTY!
    return _getDefaultPermissionsForRole(cleanRole);
  }

  @override
  Future<void> updateRolePermission(String role, String permissionKey, bool isEnabled) async {
    final cleanRole = role.toLowerCase().trim();
    // ignore: avoid_print
    print('DEBUG: Supabase update_role_permission: role=$cleanRole, key=$permissionKey, enabled=$isEnabled');

    try {
      await _supabase.rpc('update_role_permission', params: {
        'p_role': cleanRole,
        'p_permission_key': permissionKey,
        'p_is_enabled': isEnabled,
      });
    } catch (e) {
      // ignore: avoid_print
      print('PermissionsRemoteSource: RPC update_role_permission failed: $e. Falling back to table upsert.');
      try {
        await _supabase.from('role_permissions').upsert({
          'role': cleanRole,
          'permission_key': permissionKey,
          'is_enabled': isEnabled,
        });
      } catch (upsertError) {
        // ignore: avoid_print
        print('PermissionsRemoteSource: Table upsert failed: $upsertError');
      }
    }
  }

  static List<PermissionItemModel> _getDefaultPermissionsForRole(String role) {
    final isCashier = role == 'cashier';
    return [
      PermissionItemModel(
        key: 'menu_view',
        nameAr: 'عرض المنيو',
        nameEn: 'View Menu',
        category: 'POS & Menu',
        descriptionAr: 'عرض قائمة الطعام والمشروبات والخدمات',
        descriptionEn: 'View food, drinks, and services menu',
        isEnabled: true,
      ),
      PermissionItemModel(
        key: 'menu_edit_prices',
        nameAr: 'تعديل أسعار المنيو',
        nameEn: 'Edit Menu Prices',
        category: 'POS & Menu',
        descriptionAr: 'تعديل أسعار الأصناف والخدمات',
        descriptionEn: 'Edit prices of items and services',
        isEnabled: !isCashier,
      ),
      PermissionItemModel(
        key: 'shift_start',
        nameAr: 'فتح شيفت',
        nameEn: 'Start Shift',
        category: 'Shifts',
        descriptionAr: 'إمكانية فتح شيفت جديد كاشير',
        descriptionEn: 'Ability to open a new cashier shift',
        isEnabled: true,
      ),
      PermissionItemModel(
        key: 'shift_close',
        nameAr: 'تقفيل شيفت',
        nameEn: 'Close Shift',
        category: 'Shifts',
        descriptionAr: 'إمكانية تقفيل الشيفت الحالي وإدخال العهدة',
        descriptionEn: 'Ability to close shift and count cash drawer',
        isEnabled: true,
      ),
      PermissionItemModel(
        key: 'shift_view_expected_cash',
        nameAr: 'رؤية الكاش المتوقع',
        nameEn: 'View Expected Cash',
        category: 'Shifts',
        descriptionAr: 'عرض المبلغ المتوقع حسابه من الجلسات',
        descriptionEn: 'View system calculated cash total',
        isEnabled: false,
      ),
      PermissionItemModel(
        key: 'booking_discount_apply',
        nameAr: 'تطبيق خصومات مباشرة',
        nameEn: 'Apply Direct Discounts',
        category: 'Financials',
        descriptionAr: 'تطبيق خصم مباشر على فاتورة الحجز',
        descriptionEn: 'Apply direct discount to booking invoices',
        isEnabled: true,
      ),
    ];
  }
}
