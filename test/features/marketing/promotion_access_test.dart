import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/marketing/presentation/promotion_access.dart';

void main() {
  const owner = UserEntity(
    id: 'owner',
    email: '',
    name: '',
    role: UserRole.owner,
    loungeId: 'own-venue',
  );
  const admin = UserEntity(
    id: 'admin',
    email: '',
    name: '',
    role: UserRole.superAdmin,
  );

  bool allowed(UserEntity? actor, String? venue, {bool permission = true}) =>
      canManagePromotion(
        user: actor,
        promotionLoungeId: venue,
        hasMarketingPermission: permission,
      );

  test('venue marketing permission cannot manage platform offers', () {
    expect(allowed(owner, null), isFalse);
    expect(allowed(owner, 'another-venue'), isFalse);
    expect(allowed(owner, 'own-venue'), isTrue);
  });

  test('venue offers require the current marketing grant', () {
    expect(allowed(owner, 'own-venue', permission: false), isFalse);
  });

  test('active platform administrators manage global and venue offers', () {
    expect(allowed(admin, null, permission: false), isTrue);
    expect(allowed(admin, 'another-venue', permission: false), isTrue);
  });

  test('missing, banned and inactive actors cannot manage offers', () {
    expect(allowed(null, null), isFalse);
    expect(allowed(admin.copyWith(isBanned: true), null), isFalse);
    expect(allowed(admin.copyWith(isActive: false), null), isFalse);
    expect(allowed(owner.copyWith(isBanned: true), 'own-venue'), isFalse);
    expect(allowed(owner.copyWith(isActive: false), 'own-venue'), isFalse);
  });
}
