import '../../domain/repositories/offline_cashier_repository.dart';

abstract class CashierStoreFactory {
  Future<void> dispose();
  Future<void> closeAll();
  Future<OfflineCashierRepository> open({
    required String actorId,
    required String loungeId,
  });
}
