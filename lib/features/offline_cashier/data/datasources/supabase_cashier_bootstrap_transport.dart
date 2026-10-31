import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/cashier_connection_mode.dart';
import 'cashier_auth_request.dart';
import 'cashier_bootstrap_transport.dart';
import 'cashier_bootstrap_validator.dart';

class SupabaseCashierBootstrapTransport implements CashierBootstrapTransport {
  final SupabaseClient client;
  final String actorId;
  const SupabaseCashierBootstrapTransport(this.client, this.actorId);

  @override
  Future<Map<String, dynamic>> load({
    required String loungeId,
    required String deviceId,
    required CashierConnectionMode mode,
  }) async {
    final response = await CashierAuthRequest.run(
      client,
      actorId,
      () => client.rpc(
        'bootstrap_offline_cashier',
        params: {
          'p_lounge_id': loungeId,
          'p_device_id': deviceId,
          'p_online': mode == CashierConnectionMode.online,
        },
      ),
    );
    if (response is! Map) throw CashierBootstrapValidator.invalid;
    return Map<String, dynamic>.from(response);
  }
}
