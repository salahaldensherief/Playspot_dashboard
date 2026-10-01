import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/local_cashier_command.dart';
import '../entities/cashier_sync_result.dart';
import '../entities/cashier_connection_mode.dart';

abstract class OfflineCashierRepository {
  Future<void> close();
  Future<Either<Failure, Map<String, dynamic>>> execute(
    LocalCashierCommand command,
  );
  Future<Either<Failure, Map<String, dynamic>>> snapshot();
  Future<Either<Failure, CashierSyncResult>> synchronize();
  Future<Either<Failure, Map<String, dynamic>>> refreshAuthority({
    required String deviceId,
    required CashierConnectionMode mode,
  });
}
