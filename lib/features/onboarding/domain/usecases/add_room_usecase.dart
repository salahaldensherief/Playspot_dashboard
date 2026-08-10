import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/core/usecases/base_usecase.dart';
import '../../../rooms/domain/entities/room_entity.dart';
import '../repositories/onboarding_repository.dart';

class AddRoomUseCase extends UseCase<RoomEntity, RoomEntity> {
  final OnboardingRepository repository;

  AddRoomUseCase(this.repository);

  @override
  Future<Either<Failure, RoomEntity>> call(RoomEntity params) async {
    return await repository.addRoom(params);
  }
}
