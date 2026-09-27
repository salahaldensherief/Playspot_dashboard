import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShiftRealtimeSubscriptionManager {
  final SupabaseClient client;
  RealtimeChannel? _realtimeChannel;

  ShiftRealtimeSubscriptionManager([SupabaseClient? client])
      : client = client ?? Supabase.instance.client;

  void subscribe({
    required String loungeId,
    required VoidCallback onShiftChanged,
    required VoidCallback onOverviewChanged,
  }) {
    if (loungeId.isEmpty) return;
    unsubscribe();

    try {
      _realtimeChannel = client
          .channel('shifts_realtime_$loungeId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'shifts',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'lounge_id',
              value: loungeId,
            ),
            callback: (payload) {
              debugPrint('⚡ [Realtime] Shift event received: ${payload.eventType}');
              onOverviewChanged();
              onShiftChanged();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'shift_payments',
            callback: (payload) {
              debugPrint('⚡ [Realtime] Shift payment event received: ${payload.eventType}');
              onOverviewChanged();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'shift_expenses',
            callback: (payload) {
              debugPrint('⚡ [Realtime] Shift expense event received: ${payload.eventType}');
              onOverviewChanged();
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('⚠️ [ShiftRealtime] Subscription error: $e');
    }
  }

  void unsubscribe() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }
}
