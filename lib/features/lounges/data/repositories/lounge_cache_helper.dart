import 'package:play_spot_dashboard/core/services/local_cache_service.dart';
import 'package:play_spot_dashboard/features/lounges/data/datasources/lounge_remote_data_source.dart';
import 'package:play_spot_dashboard/features/lounges/data/models/lounge_model.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';

class LoungeCacheHelper {
  static const String cacheLoungesKey = 'cache_lounges_v2';
  final LocalCacheService localCacheService;
  final LoungeRemoteDataSource remoteDataSource;

  LoungeCacheHelper(this.localCacheService, this.remoteDataSource);

  LoungeModel toModel(Lounge l) {
    return LoungeModel(
      id: l.id,
      name: l.name,
      imageUrl: l.imageUrl,
      rating: l.rating,
      distance: l.distance,
      pricePerHour: l.pricePerHour,
      isOpen: l.isOpen,
      location: l.location,
      city: l.city,
      totalReviews: l.totalReviews,
      availableRooms: l.availableRooms,
      descriptionAr: l.descriptionAr,
      descriptionEn: l.descriptionEn,
      images: l.images,
      opensAt: l.opensAt,
      closesAt: l.closesAt,
      lat: l.lat,
      lng: l.lng,
      categoryIcons: l.categoryIcons,
      categoryId: l.categoryId,
      ownerName: l.ownerName,
      ownerEmail: l.ownerEmail,
      status: l.status,
      hasDiscount: l.hasDiscount,
      discountPercentage: l.discountPercentage,
      discountTitleAr: l.discountTitleAr,
      discountTitleEn: l.discountTitleEn,
      discountExpiresAt: l.discountExpiresAt,
    );
  }

  List<Lounge>? getCachedLounges() {
    final cached = localCacheService.getJson(cacheLoungesKey);
    if (cached is List && cached.isNotEmpty) {
      try {
        final list = cached
            .map((item) => LoungeModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .where((e) => e.status != 'deleted')
            .map((e) => e as Lounge)
            .toList();
        if (list.isNotEmpty) return list;
      } catch (_) {
        localCacheService.remove(cacheLoungesKey);
      }
    }
    return null;
  }

  Future<void> cacheLounges(List<LoungeModel> lounges) async {
    final models = lounges.map(toModel).toList();
    await localCacheService.setJson(
      cacheLoungesKey,
      models.map((m) => m.toJson()).toList(),
    );
  }

  void refreshLoungesInBackground() async {
    try {
      final lounges = await remoteDataSource.getLounges();
      await cacheLounges(lounges);
    } catch (_) {}
  }

  Lounge? getCachedLoungeById(String id) {
    final cached = localCacheService.getJson('cache_lounge_$id');
    if (cached is Map) {
      try {
        return LoungeModel.fromJson(Map<String, dynamic>.from(cached));
      } catch (_) {
        localCacheService.remove('cache_lounge_$id');
      }
    }
    return null;
  }

  Future<void> cacheLoungeById(String id, LoungeModel lounge) async {
    final model = toModel(lounge);
    await localCacheService.setJson('cache_lounge_$id', model.toJson());
  }

  void refreshLoungeByIdInBackground(String id) async {
    try {
      final lounge = await remoteDataSource.getLoungeById(id);
      if (lounge != null) {
        await cacheLoungeById(id, lounge);
      }
    } catch (_) {}
  }

  Future<void> invalidateLounge(String id) async {
    await localCacheService.remove('cache_lounges');
    await localCacheService.remove(cacheLoungesKey);
    await localCacheService.remove('cache_lounge_$id');
  }
}
