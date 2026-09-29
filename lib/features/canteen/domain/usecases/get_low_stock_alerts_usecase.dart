import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/low_stock_alert_entity.dart';
import '../repositories/canteen_repository.dart';

class GetLowStockAlertsUseCase
    implements UseCase<List<LowStockAlertEntity>, String> {
  final CanteenRepository repository;

  GetLowStockAlertsUseCase(this.repository);

  @override
  Future<Either<Failure, List<LowStockAlertEntity>>> call(String loungeId) {
    return repository.getLowStockAlerts(loungeId: loungeId);
  }
}
