import 'package:equatable/equatable.dart';

enum UserRole {
  superAdmin,
  loungeOwner,
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
  bool get isCashier => role == UserRole.cashier;
  bool get isStaff => role == UserRole.loungeOwner || role == UserRole.cashier;

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
