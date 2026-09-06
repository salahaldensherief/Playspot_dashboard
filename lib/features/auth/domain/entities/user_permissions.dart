import 'package:get_it/get_it.dart';
import 'package:play_spot_dashboard/features/permissions/presentation/cubit/permissions_cubit.dart';
import 'user_entity.dart';

/// A centralized class to manage all Role-Based Access Control (RBAC) logic.
/// This keeps UserEntity clean and provides a single source of truth for permissions.
class UserPermissions {
  final UserRole role;

  const UserPermissions(this.role);

  // --- Role Groups ---
  
  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isOwner => role == UserRole.owner;
  bool get isManager => role == UserRole.manager;
  bool get isCashier => role == UserRole.cashier;
  bool get isStaffRole => role == UserRole.staff;

  /// Admins (Owner & Manager) who manage the lounge
  bool get isLoungeAdmin => isOwner || isManager;

  /// Anyone who is part of the lounge staff (Owner, Manager, Cashier, etc.)
  bool get isStaff => isOwner || isManager || isCashier || isStaffRole;

  /// Evaluates dynamic permission via PermissionsCubit if registered
  bool can(String key) {
    if (isSuperAdmin || isOwner) return true;
    if (GetIt.I.isRegistered<PermissionsCubit>()) {
      try {
        return GetIt.I<PermissionsCubit>().hasPermission(key, userRole: role.name);
      } catch (_) {}
    }
    // Default Fallbacks
    if (isManager) return true;
    if (isCashier) {
      if ([
        'staff_management',
        'financials_view',
        'reports_view',
        'shifts_view',
        'shifts_approve',
        'menu_edit_prices',
        'menu_manage_items',
        'rooms_manage',
        'marketing_manage',
        'lounge_profile_edit',
      ].contains(key)) {
        return false;
      }
    }
    return true;
  }

  // --- Feature Permissions ---

  /// Who can add, edit, or delete staff members?
  bool get canManageStaff => can('staff_management');

  /// Who can see payouts, bank details, and financial summaries?
  bool get canViewFinancials => can('financials_view');

  /// Who can view advanced analytics and monthly reports?
  bool get canViewReports => can('reports_view');

  /// Who can view shift history?
  bool get canViewShiftHistory => can('shifts_view');

  /// Who can manage the lounge's setup (Rooms, Extras, etc.)?
  bool get canEditSetup => can('rooms_view') || can('menu_view') || can('rooms_manage') || can('menu_manage_items');

  /// Who can create and manage marketing campaigns/promotions?
  bool get canManageMarketing => can('marketing_manage');

  /// Who can toggle the lounge "Open/Closed" status?
  bool get canToggleLoungeStatus => can('lounge_toggle_status');

  /// Who can edit the lounge's public profile (Description, Images, Location)?
  bool get canEditLoungeProfile => can('lounge_profile_edit');

  // --- Inventory & Menu Permissions ---

  /// Who can change the structure of the menu (Add/Delete/Price Extras)?
  bool get canManageMenuStructure => can('menu_manage_items');

  /// Who can only update the quantities (Stock) of items?
  bool get canUpdateStockOnly => can('extras_update_stock');

  // --- Workflow Enforcement ---

  /// Who is forced to open/close shifts to operate the system?
  bool get needsShift => isCashier;
  
  // --- UI Helpers ---
  
  /// Should the shift banner be visible for this user?
  bool get shouldShowShiftBanner => !isSuperAdmin;
}
