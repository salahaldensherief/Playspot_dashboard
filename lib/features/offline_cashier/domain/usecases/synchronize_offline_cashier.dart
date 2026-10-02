import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/cashier_sync_result.dart';
import '../repositories/offline_cashier_repository.dart';

class SynchronizeOfflineCashier {
  final OfflineCashierRepository repository;
  const SynchronizeOfflineCashier(this.repository);
  Future<Either<Failure, CashierSyncResult>> call() => repository.synchronize();
}
