class PermissionKey {
  static const _aliases = <String, String>{
    'bookings_view': 'bookings.view',
    'bookings_manage': 'bookings.manage',
    'staff_management': 'staff_manage',
    'financials_view': 'payouts_manage',
    'reports_view': 'reports.view',
    'rooms_view': 'rooms_view_status',
    'pos_checkout': 'billing_checkout',
    'checkout_process': 'billing_checkout',
    'booking_discount_apply': 'billing_apply_discount',
    'menu_edit_prices': 'menu_manage_items',
    'lounge_profile_edit': 'lounges_manage_settings',
    'shifts_approve': 'shifts_review_and_approve',
    'shift_view_expected_cash': 'shifts_view_blind_cash',
    'shift_start': 'shifts_open_own',
    'shift_close': 'shifts_blind_close',
  };

  static String canonical(String key) => _aliases[key] ?? key;
}
