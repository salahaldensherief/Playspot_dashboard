import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/local_cashier_command.dart';
import '../repositories/offline_cashier_repository.dart';

class ExecuteOfflineCashierCommand {
  final OfflineCashierRepository repository;
  const ExecuteOfflineCashierCommand(this.repository);
  Future<Either<Failure, Map<String, dynamic>>> call(
    LocalCashierCommand command,
  ) => repository.execute(command);
}
