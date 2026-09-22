import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/city_entity.dart';
import '../repositories/category_repository.dart';

class GetCitiesUseCase implements UseCase<List<CityEntity>, bool> {
  final CategoryRepository repository;

  GetCitiesUseCase(this.repository);

  @override
  Future<Either<Failure, List<CityEntity>>> call(bool forceRefresh) {
    return repository.getCities(forceRefresh: forceRefresh);
  }
}

class AddCityUseCase implements UseCase<void, CityEntity> {
  final CategoryRepository repository;

  AddCityUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CityEntity city) {
    return repository.addCity(city);
  }
}

class UpdateCityUseCase implements UseCase<void, CityEntity> {
  final CategoryRepository repository;

  UpdateCityUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CityEntity city) {
    return repository.updateCity(city);
  }
}

class DeleteCityUseCase implements UseCase<void, String> {
  final CategoryRepository repository;

  DeleteCityUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) {
    return repository.deleteCity(id);
  }
}
