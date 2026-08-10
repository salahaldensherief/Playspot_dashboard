import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    super.loungeId,
    super.avatarUrl,
    super.isSetupCompleted,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['full_name']?.toString() ?? json['name']?.toString() ?? 'Unknown',
      role: json['role'] == 'super_admin' ? UserRole.superAdmin : UserRole.loungeAdmin,
      loungeId: json['lounge_id']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      isSetupCompleted: json['is_setup_completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': name,
      'role': role.toString().split('.').last == 'superAdmin' ? 'super_admin' : 'lounge_admin',
      'lounge_id': loungeId,
      'avatar_url': avatarUrl,
      'is_setup_completed': isSetupCompleted,
    };
  }
}
