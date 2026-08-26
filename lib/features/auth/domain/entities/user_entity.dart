import 'package:equatable/equatable.dart';

enum UserRole {
  superAdmin,
  loungeOwner,
  manager,
  cashier,
  user,
}

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? loungeId;
  final String? avatarUrl;
  final bool isSetupCompleted;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.loungeId,
    this.avatarUrl,
    this.isSetupCompleted = false,
  });

  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isLoungeOwner => role == UserRole.loungeOwner;
  bool get isManager => role == UserRole.manager;
  bool get isCashier => role == UserRole.cashier;

  /// High-level permissions
  bool get canManageStaff => isLoungeOwner || isSuperAdmin;
  bool get canViewFinancials => isLoungeOwner || isSuperAdmin;
  bool get canEditSetup => isLoungeOwner || isSuperAdmin || isManager;
  bool get canManageMarketing => isLoungeOwner || isSuperAdmin || isManager;
  bool get canToggleLoungeStatus => isLoungeOwner || isSuperAdmin || isManager;
  bool get isStaff => role == UserRole.loungeOwner || role == UserRole.manager || role == UserRole.cashier;

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        role,
        loungeId,
        avatarUrl,
        isSetupCompleted,
      ];
}
