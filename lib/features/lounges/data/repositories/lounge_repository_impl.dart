import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/core/services/local_cache_service.dart';
import 'package:play_spot_dashboard/features/lounges/data/datasources/lounge_remote_data_source.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/activity.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/extra_entity.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/room.dart';
import 'package:play_spot_dashboard/features/lounges/domain/repositories/lounge_repository.dart';
import 'package:play_spot_dashboard/features/rooms/data/models/room_model.dart';
import 'lounge_analytics_repository_helper.dart';
import 'lounge_cache_helper.dart';
import 'lounge_extras_repository_helper.dart';

class LoungeRepositoryImpl implements LoungeRepository {
  final LoungeRemoteDataSource remoteDataSource;
  final LocalCacheService localCacheService;

  late final LoungeCacheHelper _cacheHelper;
  late final LoungeExtrasRepositoryHelper _extrasHelper;
  late final LoungeAnalyticsRepositoryHelper _analyticsHelper;

  LoungeRepositoryImpl(this.remoteDataSource, this.localCacheService) {
    _cacheHelper = LoungeCacheHelper(localCacheService, remoteDataSource);
    _extrasHelper = LoungeExtrasRepositoryHelper(remoteDataSource, localCacheService);
    _analyticsHelper = LoungeAnalyticsRepositoryHelper(remoteDataSource);
  }

  @override
  Future<Either<Failure, List<Lounge>>> getLounges({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        final cached = _cacheHelper.getCachedLounges();
        if (cached != null) {
          _cacheHelper.refreshLoungesInBackground();
          return Right(cached);
        }
      }

      final lounges = await remoteDataSource.getLounges();
      if (lounges.isEmpty) {
        final cached = _cacheHelper.getCachedLounges();
        if (cached != null) return Right(cached);
      } else {
        await _cacheHelper.cacheLounges(lounges);
      }
      return Right(lounges.map((e) => e as Lounge).toList());
    } catch (e) {
      final cached = _cacheHelper.getCachedLounges();
      if (cached != null) return Right(cached);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Lounge>>> getOwnerBranches(String ownerId, {bool forceRefresh = false}) async {
    try {
      final branches = await remoteDataSource.getOwnerBranches(ownerId);
      return Right(branches.map((e) => e as Lounge).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> addLoungeBranch(Map<String, dynamic> branchData) async {
    try {
      final res = await remoteDataSource.addLoungeBranch(branchData);
      final newId = res['id']?.toString() ?? res['lounge_id']?.toString() ?? '';
      return Right(newId);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getMultiBranchOverview({
    required String ownerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final overview = await remoteDataSource.getMultiBranchOverview(
        ownerId: ownerId,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(overview);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Lounge?>> getLoungeById(String id, {bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        final cached = _cacheHelper.getCachedLoungeById(id);
        if (cached != null) {
          _cacheHelper.refreshLoungeByIdInBackground(id);
          return Right(cached);
        }
      }

      final lounge = await remoteDataSource.getLoungeById(id);
      if (lounge != null) {
        await _cacheHelper.cacheLoungeById(id, lounge);
      }
      return Right(lounge);
    } catch (e) {
      final cached = _cacheHelper.getCachedLoungeById(id);
      if (cached != null) return Right(cached);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createLounge(Lounge lounge) async {
    try {
      final model = _cacheHelper.toModel(lounge);
      final id = await remoteDataSource.createLounge(model);
      await _cacheHelper.invalidateLounge(id);
      return Right(id);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createLoungeAdmin({
    required String email,
    required String password,
    required String name,
    required String loungeId,
  }) async {
    try {
      await remoteDataSource.createLoungeAdmin(
        email: email,
        password: password,
        name: name,
        loungeId: loungeId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLounge(Lounge lounge) async {
    try {
      final model = _cacheHelper.toModel(lounge);
      await remoteDataSource.updateLounge(lounge.id, model.toJson());
      await _cacheHelper.invalidateLounge(lounge.id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLoungeDiscount({
    required String loungeId,
    required bool hasDiscount,
    required int discountPercentage,
    String? titleAr,
    String? titleEn,
    DateTime? expiresAt,
    String? vodafoneCashNumber,
    String? instapayAccount,
  }) async {
    try {
      await remoteDataSource.updateLoungeDiscount(
        loungeId,
        hasDiscount: hasDiscount,
        discountPercentage: discountPercentage,
        titleAr: titleAr,
        titleEn: titleEn,
        expiresAt: expiresAt,
        vodafoneCashNumber: vodafoneCashNumber,
        instapayAccount: instapayAccount,
      );
      await _cacheHelper.invalidateLounge(loungeId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLoungePolicies({
    required String loungeId,
    required bool allowCashPayment,
    required bool requirePrepaidFirstTime,
    required int cashGracePeriodMinutes,
    String? vodafoneCashNumber,
    String? instapayAccount,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'allow_cash_payment': allowCashPayment,
        'require_prepaid_first_time': requirePrepaidFirstTime,
        'cash_grace_period_minutes': cashGracePeriodMinutes,
        if (vodafoneCashNumber != null) 'vodafone_cash_number': vodafoneCashNumber.trim(),
        if (instapayAccount != null) 'instapay_account': instapayAccount.trim(),
      };
      await remoteDataSource.updateLounge(loungeId, updateData);
      await _cacheHelper.invalidateLounge(loungeId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLoungeLocation(String loungeId, double lat, double lng) async {
    try {
      await remoteDataSource.updateLounge(loungeId, {
        'location_point': 'POINT($lng $lat)',
      });
      await _cacheHelper.invalidateLounge(loungeId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createLoungeWithOwner({
    required String email,
    required String password,
    required String ownerName,
    required String loungeName,
    String? city,
    String? address,
    String? phone,
  }) async {
    try {
      final res = await remoteDataSource.createLoungeWithOwner(
        email: email,
        password: password,
        ownerName: ownerName,
        loungeName: loungeName,
        city: city,
        address: address,
        phone: phone,
      );
      final loungeId = res['lounge_id']?.toString() ?? '';
      await _cacheHelper.invalidateLounge(loungeId);
      return Right(loungeId);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDashboardStats(String? loungeId) =>
      _analyticsHelper.getDashboardStats(loungeId);

  @override
  Future<Either<Failure, Map<String, dynamic>>> getDashboardOverview() =>
      _analyticsHelper.getDashboardOverview();

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getRevenueOverTime(int daysBack) =>
      _analyticsHelper.getRevenueOverTime(daysBack);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getTopLoungesByRevenue(int limitCount) =>
      _analyticsHelper.getTopLoungesByRevenue(limitCount);

  @override
  Future<Either<Failure, List<ExtraEntity>>> getExtras(String loungeId, {bool forceRefresh = false}) =>
      _extrasHelper.getExtras(loungeId, forceRefresh: forceRefresh);

  @override
  Future<Either<Failure, void>> addExtra(ExtraEntity extra) =>
      _extrasHelper.addExtra(extra);

  @override
  Future<Either<Failure, void>> updateExtra(ExtraEntity extra) =>
      _extrasHelper.updateExtra(extra);

  @override
  Future<Either<Failure, void>> deleteExtra(String extraId) =>
      _extrasHelper.deleteExtra(extraId);

  @override
  Future<Either<Failure, void>> toggleExtraStock(String extraId, bool isOutOfStock) =>
      _extrasHelper.toggleExtraStock(extraId, isOutOfStock);

  @override
  Future<Either<Failure, void>> toggleLoungeOpenStatus(String loungeId, bool isOpen) async {
    try {
      await remoteDataSource.toggleLoungeOpenStatus(loungeId, isOpen);
      await _cacheHelper.invalidateLounge(loungeId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Activity>>> getActivities(String roomId) async {
    try {
      final data = await remoteDataSource.getActivities(roomId);
      final activities = data.map((json) {
        final type = json['activity_types'];
        return Activity(
          id: json['id']?.toString() ?? '',
          roomId: json['room_id']?.toString() ?? '',
          name: type?['label'] ?? type?['name_en'] ?? type?['name'] ?? '',
          pricePerHour: (json['price_override'] ?? type?['default_price'] ?? 0.0).toDouble(),
          type: type?['category'] ?? '',
        );
      }).toList();
      return Right(activities);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Room>>> getRooms(String loungeId) async {
    try {
      final List<RoomModel> roomModels = await remoteDataSource.getRooms(loungeId);
      final rooms = roomModels.map((m) => Room(
        id: m.id,
        loungeId: m.loungeId,
        name: m.nameEn.isEmpty ? m.nameAr : m.nameEn,
        type: m.spaceType ?? '',
      )).toList();
      return Right(rooms);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteLounge(String id) async {
    try {
      await remoteDataSource.deleteLounge(id);
      await _cacheHelper.invalidateLounge(id);
      return const Right(null);
    } catch (e) {
      await _cacheHelper.invalidateLounge(id);
      return Left(ServerFailure(e.toString()));
    }
  }
}
