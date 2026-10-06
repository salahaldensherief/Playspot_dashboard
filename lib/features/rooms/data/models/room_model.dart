import '../../domain/entities/room_entity.dart';

class RoomModel extends RoomEntity {
  const RoomModel({
    required super.id,
    required super.loungeId,
    required super.nameAr,
    required super.nameEn,
    super.descriptionAr,
    super.descriptionEn,
    super.activityNames = const [],
    super.activityIds = const [],
    super.spaceType,
    required super.spaceTypeId,
    super.maxCapacity,
    super.capacity,
    super.hourlyRateSingle,
    super.hourlyRateMulti,
    super.pricePerHourSingle,
    super.pricePerHourMulti,
    super.pricePerHour,
    super.extraControllerPrice,
    required super.isAvailable,
    required super.images,
    required super.featuresAr,
    required super.featuresEn,
    super.controllersCount,
    super.screenSize,
    super.resourceType,
    super.requiresScreen,
    super.requiresControllers,
    super.pricingModel,
    super.status,
    super.hasOffer,
    super.offerTitle,
    super.offerTag,
    super.activePromotionId,
    super.openTimeEnabled,
    super.openTimePricingMode,
    super.openTimeCustomHourlyRate,
    super.openTimePriceMultiplier,
    super.openTimeMinimumMinutes,
    super.openTimeRoundingMinutes,
    super.openTimeMaxMinutes,
    super.openTimeBufferBeforeBookingMinutes,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    final List? activitiesJoin = json['room_activities'] as List?;
    final List<String> activities = [];
    final List<String> activityIds = [];
    if (activitiesJoin != null) {
      for (var item in activitiesJoin) {
        if (item['activity_types'] != null) {
          final type = item['activity_types'];
          if (type['label'] != null) {
            activities.add(type['label']);
          } else if (type['name_en'] != null) {
            activities.add(type['name_en']);
          }

          if (type['id'] != null) {
            activityIds.add(type['id'].toString());
          }
        }
      }
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    int parseInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? defaultValue;
    }

    RoomStatusEnum parseStatus(String? status) {
      switch (status) {
        case 'maintenance':
          return RoomStatusEnum.maintenance;
        case 'occupied':
          return RoomStatusEnum.occupied;
        default:
          return RoomStatusEnum.available;
      }
    }

    final double singleRate = parseDouble(
      json['hourly_rate_single'] ??
          json['price_per_hour_single'] ??
          json['price_per_hour'],
    );

    final double multiRate = parseDouble(
      json['hourly_rate_multi'] ??
          json['price_per_hour_multi'] ??
          json['price_per_hour'],
    );

    return RoomModel(
      id: json['id']?.toString() ?? '',
      loungeId: json['lounge_id']?.toString() ?? '',
      nameAr: (json['name_ar'] ?? json['name'])?.toString() ?? '',
      nameEn: (json['name_en'] ?? json['name'])?.toString() ?? '',
      descriptionAr: json['description_ar']?.toString() ?? '',
      descriptionEn: json['description_en']?.toString() ?? '',
      activityNames: activities.isNotEmpty
          ? activities
          : (json['activity_names'] != null
                ? List<String>.from(json['activity_names'])
                : []),
      activityIds: activityIds.isNotEmpty
          ? activityIds
          : (json['activity_ids'] != null
                ? List<String>.from(json['activity_ids'])
                : []),
      spaceType:
          json['space_types']?['name'] ?? json['space_type_name']?.toString(),
      spaceTypeId: json['space_type_id']?.toString() ?? '',
      maxCapacity: parseInt(json['max_capacity'] ?? json['capacity'], 4),
      hourlyRateSingle: singleRate,
      hourlyRateMulti: multiRate,
      extraControllerPrice: parseDouble(json['extra_controller_price']),
      isAvailable: json['is_available'] ?? json['is_active'] ?? true,
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      featuresAr: json['features_ar'] != null
          ? List<String>.from(json['features_ar'])
          : [],
      featuresEn: json['features_en'] != null
          ? List<String>.from(json['features_en'])
          : [],
      controllersCount: parseInt(json['controllers_count'], 2),
      screenSize: json['screen_size']?.toString() ?? '',
      resourceType: json['resource_type']?.toString() ?? 'console',
      requiresScreen: json['requires_screen'] as bool? ?? true,
      requiresControllers: json['requires_controllers'] as bool? ?? true,
      pricingModel:
          json['pricing_model']?.toString() ?? 'single_multi_hour',
      status: parseStatus(json['status']),
      openTimeEnabled: json['open_time_enabled'] == true,
      openTimePricingMode:
          json['open_time_pricing_mode']?.toString() ?? 'same_hourly',
      openTimeCustomHourlyRate: json['open_time_custom_hourly_rate'] == null
          ? null
          : parseDouble(json['open_time_custom_hourly_rate']),
      openTimePriceMultiplier:
          parseDouble(json['open_time_price_multiplier']) <= 0
          ? 1.0
          : parseDouble(json['open_time_price_multiplier']),
      openTimeMinimumMinutes: parseInt(json['open_time_minimum_minutes'], 30),
      openTimeRoundingMinutes: parseInt(json['open_time_rounding_minutes'], 15),
      openTimeMaxMinutes: json['open_time_max_minutes'] == null
          ? null
          : parseInt(json['open_time_max_minutes'], 0),
      openTimeBufferBeforeBookingMinutes: parseInt(
        json['open_time_buffer_before_booking_minutes'],
        15,
      ),
    );
  }

  Map<String, dynamic> toCacheJson() => {
    ...toJson(),
    'space_type_name': spaceType,
  };

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'lounge_id': loungeId,
      'name': nameEn.isEmpty ? 'Unnamed Room' : nameEn,
      'name_ar': nameAr,
      'name_en': nameEn,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'max_capacity': maxCapacity,
      'hourly_rate_single': hourlyRateSingle,
      'hourly_rate_multi': hourlyRateMulti,
      'extra_controller_price': extraControllerPrice,
      'is_available': isAvailable,
      'images': images,
      'features_ar': featuresAr,
      'features_en': featuresEn,
      'controllers_count': controllersCount,
      'screen_size': requiresScreen ? screenSize : '',
      'resource_type': resourceType,
      'requires_screen': requiresScreen,
      'requires_controllers': requiresControllers,
      'pricing_model': pricingModel,
      'status': switch (status) {
        RoomStatusEnum.available => 'available',
        RoomStatusEnum.maintenance => 'maintenance',
        RoomStatusEnum.occupied => 'occupied',
      },
      'open_time_enabled': openTimeEnabled,
      'open_time_pricing_mode': openTimePricingMode,
      'open_time_custom_hourly_rate': openTimeCustomHourlyRate,
      'open_time_price_multiplier': openTimePriceMultiplier,
      'open_time_minimum_minutes': openTimeMinimumMinutes,
      'open_time_rounding_minutes': openTimeRoundingMinutes,
      'open_time_max_minutes': openTimeMaxMinutes,
      'open_time_buffer_before_booking_minutes':
          openTimeBufferBeforeBookingMinutes,
    };
    if (spaceTypeId != null && spaceTypeId!.isNotEmpty) {
      data['space_type_id'] = spaceTypeId;
    }
    return data;
  }
}
