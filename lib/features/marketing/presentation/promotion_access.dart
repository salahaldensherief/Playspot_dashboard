import '../../auth/domain/entities/user_entity.dart';

/// Presentation guard matching the server's promotion ownership boundary.
bool canManagePromotion({
  required UserEntity? user,
  required String? promotionLoungeId,
  required bool hasMarketingPermission,
}) {
  if (user == null || !user.isActive || user.isBanned) return false;
  if (user.isSuperAdmin) return true;
  final loungeId = user.loungeId;
  return hasMarketingPermission &&
      loungeId != null &&
      loungeId.isNotEmpty &&
      promotionLoungeId == loungeId;
}
