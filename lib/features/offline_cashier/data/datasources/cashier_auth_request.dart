import 'package:supabase_flutter/supabase_flutter.dart';

class CashierAuthRequest {
  static Future<T> run<T>(
    SupabaseClient client,
    String actorId,
    Future<T> Function() request,
  ) async {
    _checkIdentity(client, actorId);
    var sessionEnded = false;
    final subscription = client.auth.onAuthStateChange.listen(
      (state) {
        if (state.event == AuthChangeEvent.signedOut ||
            (state.session != null && state.session?.user.id != actorId)) {
          sessionEnded = true;
        }
      },
      onError: (Object error) {
        sessionEnded = true;
      },
    );
    try {
      final result = await request();
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
