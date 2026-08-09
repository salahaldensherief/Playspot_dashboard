import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../entities/lounge.dart';
import '../entities/room.dart';
import '../entities/activity.dart';

abstract class LoungeRepository {
  Future<Either<Failure, List<Lounge>>> getLounges();
  Future<Either<Failure, List<Room>>> getRooms(String loungeId);
  Future<Either<Failure, List<Activity>>> getActivities(String roomId);
  Future<Either<Failure, void>> createLounge(Lounge lounge);
  Future<Either<Failure, void>> updateLounge(Lounge lounge);
  Future<Either<Failure, void>> deleteLounge(String id);
}
