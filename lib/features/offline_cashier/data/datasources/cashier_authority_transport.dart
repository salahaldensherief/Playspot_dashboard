import '../../domain/entities/cashier_connection_mode.dart';

abstract class CashierAuthorityTransport {
  Future<Map<String, dynamic>> refresh({
    required String loungeId,
    required String deviceId,
    required CashierConnectionMode mode,
  });
}
