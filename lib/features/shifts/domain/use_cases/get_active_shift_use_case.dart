import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/shift_entity.dart';
import '../repositories/shift_repository.dart';

class GetActiveShiftUseCase {
  final ShiftRepository repository;

  GetActiveShiftUseCase(this.repository);

  Future<Either<Failure, ShiftEntity?>> call(String loungeId) async {
    return await repository.getActiveShift(loungeId);
  }
}
