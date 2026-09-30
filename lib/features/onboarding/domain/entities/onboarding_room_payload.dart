import '../../../rooms/domain/entities/room_entity.dart';

class OnboardingRoomPayload {
  static Map<String, dynamic> fromRoom(RoomEntity room) => {
    'name': room.nameEn.isNotEmpty ? room.nameEn : room.nameAr,
    'name_ar': room.nameAr.isNotEmpty ? room.nameAr : room.nameEn,
    'name_en': room.nameEn.isNotEmpty ? room.nameEn : room.nameAr,
    'description_ar': room.descriptionAr,
    'description_en': room.descriptionEn,
    'is_available': room.isAvailable,
    'is_active': true,
    'status': room.status.name,
    'hourly_rate_single': room.hourlyRateSingle,
    'hourly_rate_multi': room.hourlyRateMulti,
    'extra_controller_price': room.extraControllerPrice,
    'max_capacity': room.maxCapacity,
    'images': room.images,
    'features_ar': room.featuresAr,
    'features_en': room.featuresEn,
    'controllers_count': room.controllersCount,
    'screen_size': room.screenSize,
    if (room.spaceTypeId?.isNotEmpty == true) 'space_type_id': room.spaceTypeId,
  };
}
