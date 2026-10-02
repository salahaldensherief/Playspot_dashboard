import 'package:play_spot_dashboard/features/offline_cashier/data/datasources/cashier_sync_transport.dart';

class FixedSessionTransport implements CashierSyncTransport {
  final Map<String, dynamic> Function(Map<String, dynamic>) respond;
  int calls = 0;
  FixedSessionTransport(this.respond);
  @override
  Future<Map<String, dynamic>> send(Map<String, dynamic> operation) async {
    calls++;
    return respond(operation);
  }
}
