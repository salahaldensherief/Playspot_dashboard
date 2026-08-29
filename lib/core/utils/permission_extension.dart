import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/login/login_cubit.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/permissions/presentation/cubit/permissions_cubit.dart';

extension PermissionExtension on BuildContext {
  /// Core permission evaluator based on the RBAC matrix
  bool hasPermission(String key) {
    final user = read<LoginCubit>().state.user;
    if (user == null) return false;

    // 1. Level 0 Bypass: Platform Admin & Lounge Owner have full access
    if (user.isSuperAdmin || user.isOwner) {
      return true;
    }

    // 2. Level 1 Bypass: Managers (Lounge Admins) bypass granular operational checks
    if (user.isManager) {
      return true;
    }

    // 3. Level 2: Cashiers & Staff use explicit Granular Permissions + Hardcoded Rules
    
    // Hardcoded logic for Cashiers based on matrix
    if (user.isCashier) {
      switch (key) {
        case 'lounge_toggle_status': // Can open/close lounge
        case 'shift_manage':        // Can open/close their own shift
        case 'pos_view_menu':       // Can see products to bill
        case 'pos_checkout':        // Can process payments
        case 'extras_update_stock':  // Can update quantities
          return true;
        case 'staff_management':
        case 'extras_edit_prices':
        case 'extras_delete_item':
        case 'view_payouts_global':
          return false;
      }
    }

    // 4. Default to Granular DB permissions for Staff or specific overrides
    return read<PermissionsCubit>().hasPermission(key);
  }
}
