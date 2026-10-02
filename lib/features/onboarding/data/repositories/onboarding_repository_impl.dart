import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/extra_entity.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_remote_data_source.dart';
import '../../domain/entities/saved_onboarding_draft.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingRemoteDataSource remoteDataSource;

  OnboardingRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, SavedOnboardingDraft>> getSavedDraft(
    String loungeId,
  ) async {
    try {
      return Right(await remoteDataSource.getSavedDraft(loungeId));
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

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
  Future<Either<Failure, Lounge>> batchCompleteOnboarding({
    required String loungeId,
    required Map<String, dynamic> loungeData,
    required List<Map<String, dynamic>> rooms,
    required List<Map<String, dynamic>> extras,
  }) async {
    try {
      final result = await remoteDataSource.batchCompleteOnboarding(
        loungeId: loungeId,
        loungeData: loungeData,
        rooms: rooms,
        extras: extras,
      );
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
        'location_point': 'POINT($lng $lat)',
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
        'opening_time': opensAt,
        'closing_time': closesAt,
        'weekly_holidays': weeklyHolidays,
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoomEntity>> addRoom(RoomEntity room) async {
    return Right(room);
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
}
