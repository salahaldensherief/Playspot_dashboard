import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/cashier_connection_mode.dart';
import '../repositories/offline_cashier_repository.dart';

class BootstrapOfflineCashier {
  final OfflineCashierRepository repository;
  const BootstrapOfflineCashier(this.repository);
  Future<Either<Failure, Map<String, dynamic>>> call({
    required String deviceId,
    required CashierConnectionMode mode,
  }) => repository.bootstrap(deviceId: deviceId, mode: mode);
}
