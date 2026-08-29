import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/live_shift_overview_entity.dart';
import '../repositories/shift_repository.dart';

class GetLoungeLiveShiftOverviewUseCase {
  final ShiftRepository repository;

  GetLoungeLiveShiftOverviewUseCase(this.repository);

  Future<Either<Failure, LiveShiftOverviewEntity>> call(String loungeId) async {
    return await repository.getLoungeLiveShiftOverview(loungeId);
  }
}
