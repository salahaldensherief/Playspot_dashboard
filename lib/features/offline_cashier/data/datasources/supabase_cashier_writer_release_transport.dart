import 'package:supabase_flutter/supabase_flutter.dart';
import 'cashier_auth_request.dart';
import 'cashier_writer_release_transport.dart';

class SupabaseCashierWriterReleaseTransport
    implements CashierWriterReleaseTransport {
  final SupabaseClient client;
  final String actorId;
  const SupabaseCashierWriterReleaseTransport(this.client, this.actorId);

  @override
  Future<Map<String, dynamic>> release(Map<String, dynamic> request) =>
      CashierAuthRequest.run(client, actorId, () async {
        Object? result;
        try {
          result = await client.rpc('release_cashier_writer', params: request);
        } on PostgrestException catch (error) {
          final key = switch (error.message) {
            'CASHIER_RELEASE_CLOSE_OWN_SHIFT_FIRST' =>
              'offline_cashier.release_close_shift',
            'CASHIER_RELEASE_ACTIVE_SESSION' =>
              'offline_cashier.release_active_session',
            'CASHIER_RELEASE_UNRESOLVED_CONFLICT' =>
              'offline_cashier.release_pending_operations',
            'CASHIER_RELEASE_SEQUENCE_MISMATCH' =>
              'offline_cashier.sequence_mismatch',
            _ =>
              error.code == '42501' || error.code == '28000'
                  ? 'offline_cashier.permission_denied'
                  : 'offline_cashier.release_unavailable',
          };
          throw StateError(key);
        }
        if (result is! Map) {
          throw const FormatException('offline_cashier.invalid_release');
        }
        return Map<String, dynamic>.from(result);
      });
}
