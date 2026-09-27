import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/shift_repository.dart';

class OpenShiftUseCase {
  final ShiftRepository repository;

  OpenShiftUseCase(this.repository);

  Future<Either<Failure, void>> call(String loungeId, double startingCash, {String? notes}) async {
    return await repository.openShift(loungeId, startingCash, notes: notes);
  }
}
