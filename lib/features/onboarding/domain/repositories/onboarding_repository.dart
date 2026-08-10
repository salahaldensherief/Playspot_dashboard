import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../../../rooms/domain/entities/room_entity.dart';
import '../../../lounges/domain/entities/extra_entity.dart';
import '../../../lounges/domain/entities/lounge.dart';

abstract class OnboardingRepository {
  Future<Either<Failure, Lounge>> setupLounge(Lounge lounge);

  Future<Either<Failure, void>> updateIdentity({
    required String loungeId,
    required String name,
    required String location,
    required double lat,
    required double lng,
    required List<String> images,
  });

  Future<Either<Failure, void>> updateOperations({
    required String loungeId,
    required String opensAt,
    required String closesAt,
    required List<int> weeklyHolidays,
  });

  Future<Either<Failure, RoomEntity>> addRoom(RoomEntity room);

  Future<Either<Failure, ExtraEntity>> addExtra(ExtraEntity extra);
  
  Future<Either<Failure, void>> completeOnboarding(String loungeId);
}
