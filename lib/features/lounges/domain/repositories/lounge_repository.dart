import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../entities/lounge.dart';
import '../entities/room.dart';
import '../entities/activity.dart';

import '../entities/extra_entity.dart';

abstract class LoungeRepository {
  Future<Either<Failure, List<Lounge>>> getLounges();
  Future<Either<Failure, Lounge?>> getLoungeById(String id);
  Future<Either<Failure, List<Room>>> getRooms(String loungeId);
  Future<Either<Failure, List<Activity>>> getActivities(String roomId);
  Future<Either<Failure, String>> createLounge(Lounge lounge);
  Future<Either<Failure, void>> createLoungeAdmin({
    required String email,
    required String password,
    required String name,
    required String loungeId,
  });
  Future<Either<Failure, void>> updateLounge(Lounge lounge);
  Future<Either<Failure, void>> updateLoungeLocation(String loungeId, double lat, double lng);
  Future<Either<Failure, void>> deleteLounge(String id);
  Future<Either<Failure, String>> createLoungeWithOwner({
    required String email,
    required String password,
    required String ownerName,
    required String loungeName,
    String? city,
  });
  Future<Either<Failure, Map<String, dynamic>>> getDashboardStats(String? loungeId);
  Future<Either<Failure, Map<String, dynamic>>> getDashboardOverview();
  Future<Either<Failure, List<Map<String, dynamic>>>> getRevenueOverTime(int daysBack);
  Future<Either<Failure, List<Map<String, dynamic>>>> getTopLoungesByRevenue(int limitCount);
  
  // Extras
  Future<Either<Failure, List<ExtraEntity>>> getExtras(String loungeId);
  Future<Either<Failure, void>> addExtra(ExtraEntity extra);
  Future<Either<Failure, void>> updateExtra(ExtraEntity extra);
  Future<Either<Failure, void>> deleteExtra(String extraId);
  Future<Either<Failure, void>> toggleExtraStock(String extraId, bool isOutOfStock);
  Future<Either<Failure, void>> toggleLoungeOpenStatus(String loungeId, bool isOpen);
}
