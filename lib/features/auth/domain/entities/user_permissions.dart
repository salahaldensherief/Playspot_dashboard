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

  // --- Feature Permissions ---

  /// Who can add, edit, or delete staff members?
  bool get canManageStaff => isLoungeAdmin || isSuperAdmin;

  /// Who can see payouts, bank details, and financial summaries?
  bool get canViewFinancials => isLoungeAdmin || isSuperAdmin;

  /// Who can view advanced analytics and monthly reports?
  bool get canViewReports => isLoungeAdmin || isSuperAdmin;

  /// Who can manage the lounge's setup (Rooms, Extras, etc.)?
  bool get canEditSetup => isLoungeAdmin || isSuperAdmin || isCashier;

  /// Who can create and manage marketing campaigns/promotions?
  bool get canManageMarketing => isLoungeAdmin || isSuperAdmin;

  /// Who can toggle the lounge "Open/Closed" status?
  bool get canToggleLoungeStatus => isLoungeAdmin || isSuperAdmin || isCashier;

  /// Who can edit the lounge's public profile (Description, Images, Location)?
  bool get canEditLoungeProfile => isLoungeAdmin || isSuperAdmin;

  // --- Inventory & Menu Permissions ---

  /// Who can change the structure of the menu (Add/Delete/Price Extras)?
  bool get canManageMenuStructure => isLoungeAdmin || isSuperAdmin;

  /// Who can only update the quantities (Stock) of items?
  bool get canUpdateStockOnly => isCashier;

  // --- Workflow Enforcement ---

  /// Who is forced to open/close shifts to operate the system?
  bool get needsShift => isCashier;
  
  // --- UI Helpers ---
  
  /// Should the shift banner be visible for this user?
  bool get shouldShowShiftBanner => !isSuperAdmin;
}
