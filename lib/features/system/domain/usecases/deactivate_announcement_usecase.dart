import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../repositories/system_repository.dart';

class DeactivateAnnouncementUseCase {
  final SystemRepository repository;

  DeactivateAnnouncementUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deactivateAnnouncement(id);
  }
}
