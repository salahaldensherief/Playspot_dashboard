import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/room.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/activity.dart';

abstract class LoungeRepository {
  Future<Either<Failure, List<Lounge>>> getLounges();
  Future<Either<Failure, List<Room>>> getRooms(String loungeId);
  Future<Either<Failure, List<Activity>>> getActivities(String roomId);
  Future<Either<Failure, void>> createLounge(Lounge lounge);
  Future<Either<Failure, void>> updateLounge(Lounge lounge);
  Future<Either<Failure, void>> deleteLounge(String id);
}
