import '../repositories/shift_repository.dart';

class OpenShiftUseCase {
  final ShiftRepository repository;

  OpenShiftUseCase(this.repository);

  Future<void> call(String loungeId, double startingCash) {
    return repository.openShift(loungeId, startingCash);
  }
}
