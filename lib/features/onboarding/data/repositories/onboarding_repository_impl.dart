import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/rooms/data/models/room_model.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/extra_entity.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_remote_data_source.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingRemoteDataSource remoteDataSource;

  OnboardingRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, Lounge>> setupLounge(Lounge lounge) async {
    try {
      final result = await remoteDataSource.setupLounge(lounge);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateIdentity({
    required String loungeId,
    required String name,
    required String location,
    required double lat,
    required double lng,
    required List<String> images,
  }) async {
    try {
      await remoteDataSource.updateLoungeData(loungeId, {
        'name': name,
        'location': location,
        'lat': lat,
        'lng': lng,
        'images': images,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateOperations({
    required String loungeId,
    required String opensAt,
    required String closesAt,
    required List<int> weeklyHolidays,
  }) async {
    try {
      await remoteDataSource.updateLoungeData(loungeId, {
        'opens_at': opensAt,
        'closes_at': closesAt,
        'weekly_holidays': weeklyHolidays,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoomEntity>> addRoom(RoomEntity room) async {
    try {
      final roomModel = RoomModel(
        
        id: room.id,
        loungeId: room.loungeId,
        nameAr: room.nameAr,
        nameEn: room.nameEn,
        activityNames: room.activityNames,
        pricePerHour: room.pricePerHour,
        capacity: room.capacity,
        images: room.images,
        featuresAr: room.featuresAr,
        featuresEn: room.featuresEn, isAvailable: room.isAvailable,
      );
      final result = await remoteDataSource.addRoom(roomModel);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExtraEntity>> addExtra(ExtraEntity extra) async {
    try {
      // Logic for adding extra
      return Right(extra); 
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> completeOnboarding(String loungeId) async {
    try {
      await remoteDataSource.updateLoungeData(loungeId, {'status': 'active'});
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
