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
    final cleanRole = role.toLowerCase().trim();
    final isManager = cleanRole == 'manager' || cleanRole == 'owner' || cleanRole == 'superadmin';
    final isCashier = cleanRole == 'cashier';

    return [
      // --- POS & Menu ---
      PermissionItemModel(
        key: 'menu_view',
        nameAr: 'عرض المنيو والأصناف',
        nameEn: 'View Menu & Items',
        category: 'category_pos',
        descriptionAr: 'عرض قائمة الطعام والمشروبات والخدمات',
        descriptionEn: 'View food, drinks, and services menu',
        isEnabled: true,
      ),
      PermissionItemModel(
        key: 'menu_manage_items',
        nameAr: 'إدارة المنيو والأصناف',
        nameEn: 'Manage Menu Items',
        category: 'category_pos',
        descriptionAr: 'إضافة وتعديل وحذف الأصناف والخدمات',
        descriptionEn: 'Add, edit, and delete menu items',
        isEnabled: isManager,
      ),
      PermissionItemModel(
        key: 'menu_edit_prices',
        nameAr: 'تعديل أسعار المنيو',
        nameEn: 'Edit Menu Prices',
        category: 'category_pos',
        descriptionAr: 'تعديل أسعار الأصناف والخدمات',
        descriptionEn: 'Edit prices of items and services',
        isEnabled: isManager,
      ),
      PermissionItemModel(
        key: 'extras_update_stock',
        nameAr: 'تعديل كميات المخزون',
        nameEn: 'Update Stock Quantities',
        category: 'category_pos',
        descriptionAr: 'تعديل الكميات المتاحة في المخزون',
        descriptionEn: 'Update available stock quantities',
        isEnabled: isManager || isCashier,
      ),
      PermissionItemModel(
        key: 'pos_checkout',
        nameAr: 'إجراء التحصيل والبيع',
        nameEn: 'Process Checkout',
        category: 'category_pos',
        descriptionAr: 'إجراء عمليات الدفع والتحصيل للعملاء',
        descriptionEn: 'Process payments and customer billing',
        isEnabled: true,
      ),

      // --- Live Ops & Rooms ---
      PermissionItemModel(
        key: 'bookings_view',
        nameAr: 'عرض العمليات والحجوزات الحية',
        nameEn: 'View Live Operations',
        category: 'category_pos',
        descriptionAr: 'رؤية شاشة الحجوزات المباشرة والأجهزة',
        descriptionEn: 'View live bookings feed and active devices',
        isEnabled: true,
      ),
      PermissionItemModel(
        key: 'rooms_view',
        nameAr: 'عرض الغرف والأجهزة',
        nameEn: 'View Rooms & Devices',
        category: 'category_pos',
        descriptionAr: 'رؤية قائمة الغرف والأجهزة في المكان',
        descriptionEn: 'View list of rooms and devices in the lounge',
        isEnabled: true,
      ),
      PermissionItemModel(
        key: 'rooms_manage',
        nameAr: 'إدارة الغرف والجلسات',
        nameEn: 'Manage Rooms & Sessions',
        category: 'category_pos',
        descriptionAr: 'إضافة وتعديل إعدادات وأسعار الغرف والجلسات',
        descriptionEn: 'Add, edit room setup and session pricing',
        isEnabled: isManager,
      ),

      // --- Shifts & Operations ---
      PermissionItemModel(
        key: 'shift_start',
        nameAr: 'فتح شيفت جديد',
        nameEn: 'Start New Shift',
        category: 'category_shifts',
        descriptionAr: 'إمكانية فتح شيفت جديد واستلام العهدة',
        descriptionEn: 'Ability to open a new shift and register cash',
        isEnabled: true,
      ),
      PermissionItemModel(
        key: 'shift_close',
        nameAr: 'تقفيل الشيفت',
        nameEn: 'Close Shift',
        category: 'category_shifts',
        descriptionAr: 'إمكانية تقفيل الشيفت وإدخال الخزينة',
        descriptionEn: 'Ability to close shift and count cash drawer',
        isEnabled: true,
      ),
      PermissionItemModel(
        key: 'shift_view_expected_cash',
        nameAr: 'رؤية الكاش المتوقع',
        nameEn: 'View Expected Cash',
        category: 'category_shifts',
        descriptionAr: 'عرض المبلغ المتوقع حسابه من النظام عند الإغلاق',
        descriptionEn: 'View system calculated cash total on close',
        isEnabled: isManager,
      ),
      PermissionItemModel(
        key: 'shifts_view',
        nameAr: 'عرض سجل الورديات',
        nameEn: 'View Shift History',
        category: 'category_shifts',
        descriptionAr: 'رؤية سجل الورديات والتقارير المترتبة عليها',
        descriptionEn: 'View history of previous cashier shifts',
        isEnabled: isManager,
      ),
      PermissionItemModel(
        key: 'shifts_approve',
        nameAr: 'اعتماد الورديات المغلقة',
        nameEn: 'Approve Closed Shifts',
        category: 'category_shifts',
        descriptionAr: 'مراجعة واعتماد المبالغ المغلقة في الشيفتات',
        descriptionEn: 'Review and approve closed cashier shifts',
        isEnabled: isManager,
      ),

      // --- Financials & Reports ---
      PermissionItemModel(
        key: 'booking_discount_apply',
        nameAr: 'تطبيق خصومات مباشرة',
        nameEn: 'Apply Direct Discounts',
        category: 'category_financials',
        descriptionAr: 'تطبيق خصم مباشر على فاتورة الحجز',
        descriptionEn: 'Apply direct discount to booking invoices',
        isEnabled: true,
      ),
      PermissionItemModel(
        key: 'financials_view',
        nameAr: 'عرض الحسابات والماليات',
        nameEn: 'View Financials & Payouts',
        category: 'category_financials',
        descriptionAr: 'رؤية تفاصيل الأرباح والمستحقات والبنك',
        descriptionEn: 'View revenue totals, bank details and payouts',
        isEnabled: isManager,
      ),
      PermissionItemModel(
        key: 'reports_view',
        nameAr: 'عرض التقارير الشهرية',
        nameEn: 'View Monthly Reports',
        category: 'category_financials',
        descriptionAr: 'رؤية التحليلات والتقارير الشهرية الشاملة',
        descriptionEn: 'View overall monthly performance reports',
        isEnabled: isManager,
      ),

      // --- Management & Settings ---
      PermissionItemModel(
        key: 'marketing_manage',
        nameAr: 'إدارة التسويق والعروض',
        nameEn: 'Manage Marketing',
        category: 'permissions',
        descriptionAr: 'إنشاء وتعديل الحملات الإعلانية والعروض',
        descriptionEn: 'Create and manage marketing promotions',
        isEnabled: isManager,
      ),
      PermissionItemModel(
        key: 'staff_management',
        nameAr: 'إدارة الموظفين والصلحيات',
        nameEn: 'Manage Staff & Roles',
        category: 'permissions',
        descriptionAr: 'إضافة موظفين جدد وتحدد أدوارهم وصلاحياتهم',
        descriptionEn: 'Add staff members and edit their permissions',
        isEnabled: isManager,
      ),
      PermissionItemModel(
        key: 'lounge_profile_edit',
        nameAr: 'تعديل ملف الصالة',
        nameEn: 'Edit Lounge Profile',
        category: 'permissions',
        descriptionAr: 'تعديل اسم وصور ووصف الصالة العام',
        descriptionEn: 'Edit public lounge description and media',
        isEnabled: isManager,
      ),
      PermissionItemModel(
        key: 'lounge_toggle_status',
        nameAr: 'تغيير حالة التشغيل (مفتوح/مغلق)',
        nameEn: 'Toggle Open/Closed Status',
        category: 'permissions',
        descriptionAr: 'تغيير حالة الصالة المباشرة للجمهور',
        descriptionEn: 'Change live lounge availability for users',
        isEnabled: isManager || isCashier,
      ),
      PermissionItemModel(
        key: 'reviews_view',
        nameAr: 'عرض تقييمات العملاء',
        nameEn: 'View Customer Reviews',
        category: 'permissions',
        descriptionAr: 'رؤية التقييمات والآراء الواردة من العملاء',
        descriptionEn: 'View customer ratings and review comments',
        isEnabled: isManager,
      ),
    ];
  }
}
