import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    super.loungeId,
    super.avatarUrl,
    super.isSetupCompleted = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    UserRole role;
    switch (json['role']) {
      case 'super_admin':
        role = UserRole.superAdmin;
        break;
      case 'lounge_admin':
        role = UserRole.loungeAdmin;
        break;
      default:
        role = UserRole.user;
    }

    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['full_name'] as String? ?? 'Unknown',
      role: role,
      loungeId: json['lounge_id'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isSetupCompleted: json['is_setup_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': name,
      'role': role.name,
      'lounge_id': loungeId,
      'avatar_url': avatarUrl,
      'is_setup_completed': isSetupCompleted,
    };
  }
}
