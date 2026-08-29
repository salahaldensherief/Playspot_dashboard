import 'package:flutter/cupertino.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    super.rawRole,
    super.loungeId,
    super.avatarUrl,
    super.isSetupCompleted = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    debugPrint('UserModel: parsing profile JSON: $json');
    final rawRoleStr = (json['role'] ?? json['out_role'])?.toString();
    return UserModel(
      id: (json['id'] ?? json['user_id'] ?? json['staff_id'])?.toString() ?? '',
      email: (json['email'] ?? json['out_email'] ?? '')?.toString() ?? '',
      name: (json['full_name'] ?? json['out_full_name'] ?? json['name'] ?? 'Unknown').toString(),
      role: roleFromString(rawRoleStr),
      rawRole: rawRoleStr,
      loungeId: (json['lounge_id'] ?? json['out_lounge_id'])?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      isSetupCompleted: json['is_setup_completed'] ?? json['out_is_setup_completed'] ?? false,
    );
  }

  static UserRole roleFromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'super_admin':
        return UserRole.superAdmin;
      case 'owner':
      case 'lounge_owner':
        return UserRole.owner;
      case 'manager':
      case 'lounge_admin':
        return UserRole.manager;
      case 'cashier':
        return UserRole.cashier;
      case 'staff':
        return UserRole.staff;
      default:
        return UserRole.user;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': name,
      'role': role.name,
      'raw_role': rawRole,
      'lounge_id': loungeId,
      'avatar_url': avatarUrl,
      'is_setup_completed': isSetupCompleted,
    };
  }
}
