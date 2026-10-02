import 'package:supabase_flutter/supabase_flutter.dart';
import 'cashier_sync_transport.dart';
import 'cashier_auth_request.dart';

class SupabaseCashierSyncTransport implements CashierSyncTransport {
  final SupabaseClient client;
  const SupabaseCashierSyncTransport(this.client);

  @override
  Future<Map<String, dynamic>> send(Map<String, dynamic> operation) async {
    final actorId = operation['actor_id'];
    if (actorId is! String) {
      throw StateError('offline_cashier.permission_denied');
    }
    final response = await CashierAuthRequest.run(
      client,
      actorId,
      () => client.rpc(
        'apply_offline_cashier_operation',
        params: {'p_operation': operation},
      ),
    );
    if (response is! Map) {
      throw const FormatException('offline_cashier.invalid_sync_response');
    }
    return Map<String, dynamic>.from(response);
  }
}
