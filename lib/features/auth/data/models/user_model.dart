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

  static bool isValidUuid(String? str) {
    if (str == null || str.trim().isEmpty) return false;
    final clean = str.trim().toLowerCase();
    if (clean == 'undefined' || clean == 'null') return false;
    return RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(clean);
  }

  static String? cleanUuid(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (isValidUuid(str)) {
      return str;
    }
    return null;
  }

  static Map<String, dynamic> sanitizeProfilePayload(Map<String, dynamic> data) {
    final cleanMap = <String, dynamic>{};
    data.forEach((key, value) {
      if (value == null) return;

      final valStr = value.toString().trim();
      final lowerStr = valStr.toLowerCase();
      if (valStr.isEmpty || lowerStr == 'undefined' || lowerStr == 'null') {
        return;
      }

      // UUID fields validation (e.g. city_id, lounge_id, level_id, user_id)
      if (key == 'city_id' || key == 'lounge_id' || key == 'level_id' || key == 'user_id' || key.endsWith('_id')) {
        if (!isValidUuid(valStr)) {
          return; // Omit invalid UUID key
        }
      }

      cleanMap[key] = value;
    });
    return cleanMap;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    debugPrint('UserModel: parsing profile JSON: $json');
    final rawRoleStr = (json['role'] ?? json['out_role'])?.toString();
    final rawAvatar = (json['avatar_url'] ?? json['out_avatar_url'])?.toString();
    final avatar = (rawAvatar != null && rawAvatar.trim().isNotEmpty) ? rawAvatar.trim() : null;

    final cityMap = json['cities'] is Map ? json['cities'] as Map : (json['city'] is Map ? json['city'] as Map : null);
    final rawCityAr = json['city_name_ar'] ?? json['out_city_name_ar'] ?? cityMap?['name_ar'];
    final rawCityEn = json['city_name_en'] ?? json['out_city_name_en'] ?? cityMap?['name_en'];

    return UserModel(
      id: (json['id'] ?? json['user_id'] ?? json['staff_id'])?.toString() ?? '',
      email: (json['email'] ?? json['out_email'] ?? '')?.toString() ?? '',
      name: (json['full_name'] ?? json['out_full_name'] ?? json['name'] ?? 'Unknown').toString(),
      role: roleFromString(rawRoleStr),
      rawRole: rawRoleStr,
      loungeId: cleanUuid(json['lounge_id'] ?? json['out_lounge_id']),
      avatarUrl: avatar,
      cityId: cleanUuid(json['city_id'] ?? json['out_city_id']),
      cityNameAr: rawCityAr?.toString(),
      cityNameEn: rawCityEn?.toString(),
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
    final rawPayload = <String, dynamic>{
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
    return sanitizeProfilePayload(rawPayload);
  }
}
