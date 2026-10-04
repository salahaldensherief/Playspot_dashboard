import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/offline_cashier_repository.dart';

class ReleaseOfflineCashierWriter {
  final OfflineCashierRepository repository;
  const ReleaseOfflineCashierWriter(this.repository);
  Future<Either<Failure, Map<String, dynamic>>> call() =>
      repository.releaseWriter();
}
