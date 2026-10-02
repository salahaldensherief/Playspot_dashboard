abstract class CashierSyncTransport {
  Future<Map<String, dynamic>> send(Map<String, dynamic> operation);
}
