import '../../../rooms/domain/entities/room_entity.dart';

class OnboardingRoomPayload {
  static Map<String, dynamic> fromRoom(RoomEntity room) => {
    'id': room.id,
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
    'activity_ids': room.activityIds,
    'resource_type': room.resourceType,
    'requires_screen': room.requiresScreen,
    'requires_controllers': room.requiresControllers,
    'pricing_model': room.pricingModel,
    'open_time_enabled': room.openTimeEnabled,
    'open_time_pricing_mode': room.openTimePricingMode,
    'open_time_custom_hourly_rate': room.openTimeCustomHourlyRate,
    'open_time_price_multiplier': room.openTimePriceMultiplier,
    'open_time_minimum_minutes': room.openTimeMinimumMinutes,
    'open_time_rounding_minutes': room.openTimeRoundingMinutes,
    'open_time_max_minutes': room.openTimeMaxMinutes,
    'open_time_buffer_before_booking_minutes':
        room.openTimeBufferBeforeBookingMinutes,
  };
}
