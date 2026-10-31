import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class CashierAuthRequest {
  static Future<T> run<T>(
    SupabaseClient client,
    String actorId,
    Future<T> Function() request, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    _checkIdentity(client, actorId);
    final initialSession = client.auth.currentSession;
    var sessionEnded = false;
    var tracking = false;
    final subscription = client.auth.onAuthStateChange.listen(
      (state) {
        // GoTrue replays historical auth events to each new listener. Drain
        // those before issuing HTTP; a new sign-in during HTTP still invalidates
        // the response even when it belongs to the same actor.
        if (!tracking) return;
        if (state.event == AuthChangeEvent.signedOut ||
            state.event == AuthChangeEvent.signedIn ||
            (state.session != null && state.session?.user.id != actorId)) {
          sessionEnded = true;
        }
      },
      onError: (Object error) {
        sessionEnded = true;
      },
    );
    try {
      await Future<void>.delayed(Duration.zero);
      _checkIdentity(client, actorId);
      if (!identical(initialSession, client.auth.currentSession)) {
        throw StateError('offline_cashier.permission_denied');
      }
      tracking = true;
      // A timeout is an uncertain server result. Callers retain the outbox or
      // release barrier and retry the same request; they never invent success.
      final result = await request().timeout(timeout);
      _checkIdentity(client, actorId);
      if (sessionEnded) throw StateError('offline_cashier.permission_denied');
      return result;
    } finally {
      await subscription.cancel();
    }
  }

  static void _checkIdentity(SupabaseClient client, String actorId) {
    if (client.auth.currentUser?.id != actorId) {
      throw StateError('offline_cashier.permission_denied');
    }
  }
}
