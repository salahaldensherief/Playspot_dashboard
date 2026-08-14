import '../../domain/entities/room_entity.dart';

class RoomModel extends RoomEntity {
  const RoomModel({
    required super.id,
    required super.loungeId,
    required super.nameAr,
    required super.nameEn,
    super.activityNames = const [],
    super.activityIds = const [],
    super.spaceType,
    required super.spaceTypeId,
    required super.capacity,
    required super.pricePerHourSingle,
    required super.pricePerHourMulti,
    super.pricePerHour,
    required super.isAvailable,
    required super.images,
    required super.featuresAr,
    required super.featuresEn,
    super.controllersCount,
    super.screenSize,
    super.status,
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

    // Helper to parse double safely
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    // Helper to parse int safely
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

    return RoomModel(
      id: json['id']?.toString() ?? '',
      loungeId: json['lounge_id']?.toString() ?? '',
      nameAr: (json['name_ar'] ?? json['name'])?.toString() ?? '',
      nameEn: (json['name_en'] ?? json['name'])?.toString() ?? '',
      activityNames: activities.isNotEmpty
          ? activities
          : (json['activity_names'] != null ? List<String>.from(json['activity_names']) : []),
      activityIds: activityIds.isNotEmpty
          ? activityIds
          : (json['activity_ids'] != null ? List<String>.from(json['activity_ids']) : []),
      spaceType: json['space_types']?['label'] ?? json['space_type_name']?.toString(),
      spaceTypeId: json['space_type_id']?.toString() ?? '',
      capacity: parseInt(json['capacity'], 4),
      pricePerHourSingle: parseDouble(json['price_per_hour_single'] ?? json['price_per_hour']),
      pricePerHourMulti: parseDouble(json['price_per_hour_multi'] ?? json['price_per_hour']),
      pricePerHour: parseDouble(json['price_per_hour']),
      isAvailable: json['is_available'] ?? true,
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      featuresAr: json['features_ar'] != null ? List<String>.from(json['features_ar']) : [],
      featuresEn: json['features_en'] != null ? List<String>.from(json['features_en']) : [],
      controllersCount: parseInt(json['controllers_count'], 2),
      screenSize: json['screen_size']?.toString() ?? '43"',
      status: parseStatus(json['status']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'lounge_id': loungeId,
      'name': nameEn.isEmpty ? 'Unnamed Room' : nameEn,
      'name_ar': nameAr,
      'name_en': nameEn,
      'capacity': capacity,
      'price_per_hour_single': pricePerHourSingle,
      'price_per_hour_multi': pricePerHourMulti,
      'price_per_hour': pricePerHourSingle, // Default for compatibility
      'is_available': isAvailable,
      'images': images,
      'features_ar': featuresAr,
      'features_en': featuresEn,
      'controllers_count': controllersCount,
      'screen_size': screenSize,
      'status': status == RoomStatusEnum.maintenance ? 'maintenance' : 'available',
    };
    if (spaceTypeId != null && spaceTypeId!.isNotEmpty) {
      data['space_type_id'] = spaceTypeId;
    }
    return data;
  }
}
