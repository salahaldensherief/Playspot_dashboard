import 'package:equatable/equatable.dart';

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

  /// Role Groups for UI Logic
  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isOwner => role == UserRole.owner;
  bool get isManager => role == UserRole.manager;
  bool get isCashier => role == UserRole.cashier;
  bool get isStaffRole => role == UserRole.staff;

  /// Compatibility Getters
  bool get isLoungeOwner => isOwner;
  bool get isStaff => isOwner || isManager || isCashier || isStaffRole;

  /// Combined Logic: Admins (Owner/Manager) bypass most restrictions
  bool get isLoungeAdmin => isOwner || isManager;
  
  /// Enforcement: Only cashiers are forced into the Shift flow
  bool get needsShift => isCashier;

  /// High-Level Permission Checkers
  bool get canManageStaff => isOwner || isSuperAdmin; 
  bool get canViewFinancials => isOwner || isSuperAdmin;
  bool get canViewReports => isLoungeAdmin || isSuperAdmin; 
  bool get canEditSetup => isLoungeAdmin || isSuperAdmin || isCashier; // Changed: Cashier can now access Rooms/Extras (Setup)
  bool get canManageMarketing => isLoungeAdmin || isSuperAdmin;
  bool get canToggleLoungeStatus => isLoungeAdmin || isSuperAdmin || isCashier; // Cashier can toggle open/closed
  bool get canEditLoungeProfile => isLoungeAdmin || isSuperAdmin;
  
  /// Menu/Extras Permission Logic
  bool get canManageMenuStructure => isLoungeAdmin || isSuperAdmin; // Add/Delete/Price
  bool get canUpdateStockOnly => isCashier; // Cashier specifically for quantities

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
