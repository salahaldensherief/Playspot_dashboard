import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/activity_type_entity.dart';
import '../repositories/category_repository.dart';

class GetActivityTypesUseCase implements UseCase<List<ActivityTypeEntity>, bool> {
  final CategoryRepository repository;

  GetActivityTypesUseCase(this.repository);

  @override
  Future<Either<Failure, List<ActivityTypeEntity>>> call(bool forceRefresh) {
    return repository.getActivityTypes(forceRefresh: forceRefresh);
  }
}

class AddActivityTypeUseCase implements UseCase<ActivityTypeEntity, ActivityTypeEntity> {
  final CategoryRepository repository;

  AddActivityTypeUseCase(this.repository);

  @override
  Future<Either<Failure, ActivityTypeEntity>> call(ActivityTypeEntity activityType) {
    return repository.addActivityType(activityType);
  }
}
