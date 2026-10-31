import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

int _nextRequestWatcher = 0;

Stream<Object?> watchRequestInvalidations(
  SupabaseClient client,
  String loungeId,
) {
  final cleanLoungeId = loungeId;
  late StreamController<Object?> controller;
  RealtimeChannel? realtimeChannel;
  var active = false;

  void emit() {
    if (active) controller.add(null);
  }

  controller = StreamController<Object?>(
    onListen: () {
      active = true;
      try {
        realtimeChannel = client.channel(
          'lounge_requests_${_nextRequestWatcher++}_$cleanLoungeId',
        );
        realtimeChannel!
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'service_calls',
              callback: (_) => emit(),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'canteen_orders',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'lounge_id',
                value: cleanLoungeId,
              ),
              callback: (_) => emit(),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'client_requests',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'lounge_id',
                value: cleanLoungeId,
              ),
              callback: (_) => emit(),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'booking_items',
              callback: (_) => emit(),
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'bookings',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'lounge_id',
                value: cleanLoungeId,
              ),
              callback: (_) => emit(),
            )
            .subscribe((status, error) {
              if (status == RealtimeSubscribeStatus.subscribed) {
                // Guarantee recovery of missed events upon connection establish or reconnect
                emit();
              } else if (status == RealtimeSubscribeStatus.channelError) {
                debugPrint(
                  '⚠️ [REQUESTS_DATA_SOURCE] Realtime Channel Error: $error',
                );
              }
            });
      } catch (error, stack) {
        controller.addError(error, stack);
      }
    },
    onCancel: () async {
      active = false;
      final channel = realtimeChannel;
      realtimeChannel = null;
      try {
        if (channel != null) await client.removeChannel(channel);
      } finally {
        unawaited(controller.close());
      }
    },
  );
  return controller.stream;
}
