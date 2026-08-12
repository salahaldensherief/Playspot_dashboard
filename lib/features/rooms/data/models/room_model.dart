import '../../domain/entities/room_entity.dart';

class RoomModel extends RoomEntity {
  const RoomModel({
    required super.id,
    required super.loungeId,
    required super.nameAr,
    required super.nameEn,
    required super.activityNames,
    super.spaceType,
    super.spaceTypeId,
    required super.capacity,
    required super.pricePerHour,
    required super.isAvailable,
    required super.images,
    required super.featuresAr,
    required super.featuresEn,
    super.controllersCount,
    super.screenSize,
    super.status,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    final List? roomCats = json['room_categories'] as List?;
    final List<String> activities = [];
    if (roomCats != null) {
      for (var cat in roomCats) {
        if (cat['categories'] != null && cat['categories']['name_en'] != null) {
          activities.add(cat['categories']['name_en']);
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

    return RoomModel(
      id: json['id']?.toString() ?? '',
      loungeId: json['lounge_id']?.toString() ?? '',
      nameAr: (json['name_ar'] ?? json['name'])?.toString() ?? '',
      nameEn: (json['name_en'] ?? json['name'])?.toString() ?? '',
      activityNames: activities.isNotEmpty
          ? activities
          : (json['activity_names'] != null ? List<String>.from(json['activity_names']) : []),
      spaceType: json['space_types']?['label'] ?? json['space_type_name']?.toString(),
      spaceTypeId: json['space_type_id']?.toString(),
      capacity: parseInt(json['capacity'], 4),
      pricePerHour: parseDouble(json['price_per_hour']),
      isAvailable: json['is_available'] ?? true,
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      featuresAr: json['features_ar'] != null ? List<String>.from(json['features_ar']) : [],
      featuresEn: json['features_en'] != null ? List<String>.from(json['features_en']) : [],
      controllersCount: parseInt(json['controllers_count'], 2),
      screenSize: json['screen_size']?.toString() ?? '43"',
      status: json['status'] == 'maintenance' ? RoomStatusEnum.maintenance : RoomStatusEnum.available,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'lounge_id': loungeId,
      'name': nameEn.isEmpty ? 'Unnamed Room' : nameEn,
      'name_ar': nameAr,
      'name_en': nameEn,
      'capacity': capacity,
      'price_per_hour': pricePerHour,
      'is_available': isAvailable,
      'images': images,
      'features_ar': featuresAr,
      'features_en': featuresEn,
      'controllers_count': controllersCount,
      'screen_size': screenSize,
      'status': status == RoomStatusEnum.maintenance ? 'maintenance' : 'available',
    };
    if (spaceTypeId != null) {
      data['space_type_id'] = spaceTypeId;
    }
    return data;
  }
}
