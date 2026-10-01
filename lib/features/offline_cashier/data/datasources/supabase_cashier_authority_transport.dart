import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/cashier_connection_mode.dart';
import 'cashier_authority_transport.dart';
import 'cashier_auth_request.dart';

class SupabaseCashierAuthorityTransport implements CashierAuthorityTransport {
  final SupabaseClient client;
  final String actorId;
  const SupabaseCashierAuthorityTransport(this.client, this.actorId);
  @override
  Future<Map<String, dynamic>> refresh({
    required String loungeId,
    required String deviceId,
    required CashierConnectionMode mode,
  }) async {
    final response = await CashierAuthRequest.run(
      client,
      actorId,
      () => client.rpc(
        'refresh_cashier_writer',
        params: {
          'p_lounge_id': loungeId,
          'p_device_id': deviceId,
          'p_online': mode == CashierConnectionMode.online,
        },
      ),
    );
    if (response is! Map) {
      throw const FormatException('offline_cashier.invalid_authority');
    }
    return Map<String, dynamic>.from(response);
  }
}
