import '../../domain/entities/cashier_connection_mode.dart';

abstract class CashierBootstrapTransport {
  Future<Map<String, dynamic>> load({
    required String loungeId,
    required String deviceId,
    required CashierConnectionMode mode,
  });
}
