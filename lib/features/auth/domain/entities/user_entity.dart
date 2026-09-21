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
  final String? cityId;
  final String? cityNameAr;
  final String? cityNameEn;
  final bool isSetupCompleted;
  final int pointsBalance;
  final int referralCount;
  final bool isBanned;
  final String? bannedReason;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.rawRole,
    this.loungeId,
    this.avatarUrl,
    this.cityId,
    this.cityNameAr,
    this.cityNameEn,
    this.isSetupCompleted = false,
    this.pointsBalance = 0,
    this.referralCount = 0,
    this.isBanned = false,
    this.bannedReason,
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
  bool get canViewReviews => permissions.canViewReviews;
  bool get canEditSetup => permissions.canEditSetup;
  bool get canManageMarketing => permissions.canManageMarketing;
  bool get canToggleLoungeStatus => permissions.canToggleLoungeStatus;
  bool get canEditLoungeProfile => permissions.canEditLoungeProfile;
  bool get canManageMenuStructure => permissions.canManageMenuStructure;
  bool get canUpdateStockOnly => permissions.canUpdateStockOnly;

  String? getDisplayCityName({String? languageCode}) {
    if (languageCode == 'en') {
      if (cityNameEn != null && cityNameEn!.trim().isNotEmpty) return cityNameEn!.trim();
      if (cityNameAr != null && cityNameAr!.trim().isNotEmpty) return cityNameAr!.trim();
    } else {
      if (cityNameAr != null && cityNameAr!.trim().isNotEmpty) return cityNameAr!.trim();
      if (cityNameEn != null && cityNameEn!.trim().isNotEmpty) return cityNameEn!.trim();
    }
    return null;
  }

  String? get displayCityName {
    return getDisplayCityName();
  }

  UserEntity copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? rawRole,
    String? loungeId,
    String? avatarUrl,
    String? cityId,
    String? cityNameAr,
    String? cityNameEn,
    bool? isSetupCompleted,
    int? pointsBalance,
    int? referralCount,
    bool? isBanned,
    String? bannedReason,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      rawRole: rawRole ?? this.rawRole,
      loungeId: loungeId ?? this.loungeId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      cityId: cityId ?? this.cityId,
      cityNameAr: cityNameAr ?? this.cityNameAr,
      cityNameEn: cityNameEn ?? this.cityNameEn,
      isSetupCompleted: isSetupCompleted ?? this.isSetupCompleted,
      pointsBalance: pointsBalance ?? this.pointsBalance,
      referralCount: referralCount ?? this.referralCount,
      isBanned: isBanned ?? this.isBanned,
      bannedReason: bannedReason ?? this.bannedReason,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        role,
        rawRole,
        loungeId,
        avatarUrl,
        cityId,
        cityNameAr,
        cityNameEn,
        isSetupCompleted,
        pointsBalance,
        referralCount,
        isBanned,
        bannedReason,
      ];
}
