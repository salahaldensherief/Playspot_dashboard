import 'package:easy_localization/easy_localization.dart';

String auditActionLabel(String value) {
  final key = switch (value.toLowerCase()) {
    'insert' => 'audit_event_insert',
    'update' => 'audit_event_update',
    'delete' => 'audit_event_delete',
    'created' => 'audit_event_created',
    'approved' => 'audit_event_approved',
    'cancelled' => 'audit_event_cancelled',
    'processing' => 'audit_event_processing',
    'booking_cancelled' => 'audit_event_booking_cancelled',
    'room_status_changed' => 'audit_event_room_status_changed',
    'opened' => 'audit_event_opened',
    'closed' => 'audit_event_closed',
    'blind_closed' => 'audit_event_blind_closed',
    _ => null,
  };
  return key?.tr() ?? 'audit_unknown_action'.tr(namedArgs: {'code': value});
}

String auditEntityLabel(String value) {
  final key = switch (value.toLowerCase()) {
    'booking' => 'booking_entity',
    'shift' => 'shift_entity',
    'room' => 'room_entity',
    'system' => 'system_entity',
    'lounge' => 'lounge_entity',
    'user' => 'user_entity',
    'payout' => 'payout_entity',
    'tournament' => 'tournament_entity',
    _ => null,
  };
  return key?.tr() ?? 'audit_unknown_entity'.tr(namedArgs: {'code': value});
}
