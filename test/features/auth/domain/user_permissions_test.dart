import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_permissions.dart';

void main() {
  group('UserPermissions Role-Based Access Control Tests', () {
    test('SuperAdmin should have all management and view permissions', () {
      const permissions = UserPermissions(UserRole.superAdmin);

      expect(permissions.isSuperAdmin, isTrue);
      expect(permissions.canManageStaff, isTrue);
      expect(permissions.canViewFinancials, isTrue);
      expect(permissions.canViewReports, isTrue);
      expect(permissions.canViewShiftHistory, isTrue);
      expect(permissions.needsShift, isFalse);
    });

    test('Lounge Owner should have full lounge management permissions', () {
      const permissions = UserPermissions(UserRole.owner);

      expect(permissions.isOwner, isTrue);
      expect(permissions.isLoungeAdmin, isTrue);
      expect(permissions.canManageStaff, isTrue);
      expect(permissions.canViewFinancials, isTrue);
      expect(permissions.canViewReports, isTrue);
      expect(permissions.canViewShiftHistory, isTrue);
      expect(permissions.canEditLoungeProfile, isTrue);
    });

    test('Lounge Manager should have management permissions', () {
      const permissions = UserPermissions(UserRole.manager);

      expect(permissions.isManager, isTrue);
      expect(permissions.isLoungeAdmin, isTrue);
      expect(permissions.canManageStaff, isTrue);
      expect(permissions.canViewFinancials, isTrue);
      expect(permissions.canViewReports, isTrue);
      expect(permissions.canViewShiftHistory, isTrue);
    });

    test('Cashier should NOT have staff, financial, report, or shift history permissions', () {
      const permissions = UserPermissions(UserRole.cashier);

      expect(permissions.isCashier, isTrue);
      expect(permissions.isLoungeAdmin, isFalse);
      expect(permissions.canManageStaff, isFalse);
      expect(permissions.canViewFinancials, isFalse);
      expect(permissions.canViewReports, isFalse);
      expect(permissions.canViewShiftHistory, isFalse);
      expect(permissions.needsShift, isTrue);
      expect(permissions.canUpdateStockOnly, isTrue);
    });
  });

  group('UserEntity Helper Proxies', () {
    test('UserEntity proxies permissions correctly', () {
      const cashierUser = UserEntity(
        id: 'u1',
        email: 'cashier@playspot.com',
        name: 'Cashier One',
        role: UserRole.cashier,
      );

      expect(cashierUser.isCashier, isTrue);
      expect(cashierUser.canViewShiftHistory, isFalse);
      expect(cashierUser.canViewReports, isFalse);

      const ownerUser = UserEntity(
        id: 'u2',
        email: 'owner@playspot.com',
        name: 'Owner One',
        role: UserRole.owner,
      );

      expect(ownerUser.isOwner, isTrue);
      expect(ownerUser.canViewShiftHistory, isTrue);
      expect(ownerUser.canViewReports, isTrue);
    });
  });
}
