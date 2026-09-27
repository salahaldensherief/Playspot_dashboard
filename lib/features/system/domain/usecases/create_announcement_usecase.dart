import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../entities/announcement_entity.dart';
import '../repositories/system_repository.dart';

class CreateAnnouncementUseCase {
  final SystemRepository repository;

  CreateAnnouncementUseCase(this.repository);

  Future<Either<Failure, void>> call(AnnouncementEntity announcement) async {
    return await repository.createAnnouncement(announcement);
  }
}
