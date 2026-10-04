import 'offline_cashier_repository.dart';

abstract class CashierWorkspaceStore {
  Future<String> deviceId();
  Future<OfflineCashierRepository> open(String actorId, String loungeId);
}
