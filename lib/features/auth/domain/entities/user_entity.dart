import 'package:equatable/equatable.dart';
import 'user_permissions.dart';

enum UserRole {
  superAdmin,
  owner,
  manager,
  cashier,
  staff,
  user,
}

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? rawRole;
  final String? loungeId;
  final String? avatarUrl;
  final bool isSetupCompleted;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.rawRole,
    this.loungeId,
    this.avatarUrl,
    this.isSetupCompleted = false,
  });

  /// Access point for all permission logic
  UserPermissions get permissions => UserPermissions(role);

  /// Role Groups (Proxied to UserPermissions for compatibility)
  bool get isSuperAdmin => permissions.isSuperAdmin;
  bool get isOwner => permissions.isOwner;
  bool get isManager => permissions.isManager;
  bool get isCashier => permissions.isCashier;
  bool get isStaffRole => permissions.isStaffRole;

  /// Compatibility Getters
  bool get isLoungeOwner => isOwner;
  bool get isStaff => permissions.isStaff;
  bool get isLoungeAdmin => permissions.isLoungeAdmin;
  bool get needsShift => permissions.needsShift;

  /// High-Level Permission Checkers (Proxied to UserPermissions)
  bool get canManageStaff => permissions.canManageStaff;
  bool get canViewFinancials => permissions.canViewFinancials;
  bool get canViewReports => permissions.canViewReports;
  bool get canViewShiftHistory => permissions.canViewShiftHistory;
  bool get canEditSetup => permissions.canEditSetup;
  bool get canManageMarketing => permissions.canManageMarketing;
  bool get canToggleLoungeStatus => permissions.canToggleLoungeStatus;
  bool get canEditLoungeProfile => permissions.canEditLoungeProfile;
  bool get canManageMenuStructure => permissions.canManageMenuStructure;
  bool get canUpdateStockOnly => permissions.canUpdateStockOnly;

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        role,
        rawRole,
        loungeId,
        avatarUrl,
        isSetupCompleted,
      ];
}
