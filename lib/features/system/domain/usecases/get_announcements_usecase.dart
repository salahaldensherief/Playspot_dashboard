import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../entities/announcement_entity.dart';
import '../repositories/system_repository.dart';

class GetAnnouncementsUseCase {
  final SystemRepository repository;

  GetAnnouncementsUseCase(this.repository);

  Future<Either<Failure, List<AnnouncementEntity>>> call() async {
    return await repository.getAnnouncements();
  }
}
