import 'package:equatable/equatable.dart';

enum UserRole {
  superAdmin,
  loungeAdmin,
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
