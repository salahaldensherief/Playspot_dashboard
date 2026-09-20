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
    super.cityId,
    super.cityNameAr,
    super.cityNameEn,
    super.isSetupCompleted = false,
    super.pointsBalance = 0,
    super.referralCount = 0,
    super.isBanned = false,
    super.bannedReason,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    debugPrint('UserModel: parsing profile JSON: $json');
    final rawRoleStr = (json['role'] ?? json['out_role'])?.toString();
    final rawAvatar = (json['avatar_url'] ?? json['out_avatar_url'])?.toString();
    final avatar = (rawAvatar != null && rawAvatar.trim().isNotEmpty) ? rawAvatar.trim() : null;
    return UserModel(
      id: (json['id'] ?? json['user_id'] ?? json['staff_id'])?.toString() ?? '',
      email: (json['email'] ?? json['out_email'] ?? '')?.toString() ?? '',
      name: (json['full_name'] ?? json['out_full_name'] ?? json['name'] ?? 'Unknown').toString(),
      role: roleFromString(rawRoleStr),
      rawRole: rawRoleStr,
      loungeId: (json['lounge_id'] ?? json['out_lounge_id'])?.toString(),
      avatarUrl: avatar,
      cityId: (json['city_id'] ?? json['out_city_id'])?.toString(),
      cityNameAr: (json['city_name_ar'] ?? json['out_city_name_ar'] ?? json['city']?['name_ar'] ?? json['cities']?['name_ar'])?.toString(),
      cityNameEn: (json['city_name_en'] ?? json['out_city_name_en'] ?? json['city']?['name_en'] ?? json['cities']?['name_en'])?.toString(),
      isSetupCompleted: json['is_setup_completed'] ?? json['out_is_setup_completed'] ?? false,
      pointsBalance: (json['points_balance'] ?? json['reward_points'] ?? json['points'] as num?)?.toInt() ?? 0,
      referralCount: (json['referral_count'] ?? json['referrals_count'] ?? json['referrals'] as num?)?.toInt() ?? 0,
      isBanned: json['is_banned'] ?? json['out_is_banned'] ?? false,
      bannedReason: json['banned_reason']?.toString(),
    );
  }

  static UserRole roleFromString(String? role) {
    switch (role?.toLowerCase().trim()) {
      case 'super_admin':
      case 'superadmin':
        return UserRole.superAdmin;
      case 'owner':
      case 'lounge_owner':
        return UserRole.owner;
      case 'manager':
      case 'lounge_admin':
      case 'admin':
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
      'city_id': cityId,
      'city_name_ar': cityNameAr,
      'city_name_en': cityNameEn,
      'is_setup_completed': isSetupCompleted,
      'points_balance': pointsBalance,
      'referral_count': referralCount,
    };
  }
}
