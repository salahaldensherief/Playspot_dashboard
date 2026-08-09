import '../../domain/entities/lounge.dart';

class LoungeModel extends Lounge {
  const LoungeModel({
    required super.id,
    required super.name,
    required super.imageUrl,
    super.rating = 0.0,
    super.distance = 0.0,
    super.pricePerHour = 0.0,
    super.isOpen = true,
    super.location,
    super.city,
    super.totalReviews,
    super.availableRooms,
    super.descriptionAr,
    super.descriptionEn,
    super.images,
    required super.opensAt,
    required super.closesAt,
    super.mapsLink,
    super.lat,
    super.lng,
    super.categoryIcons = const [],
    super.categoryId,
    super.ownerName,
    super.ownerEmail,
  });

  factory LoungeModel.fromJson(Map<String, dynamic> json) {
    double calculatedDistance = 0.0;
    if (json['dist_meters'] != null) {
      calculatedDistance = (json['dist_meters'] as num).toDouble() / 1000.0;
    } else if (json['distance'] != null) {
      calculatedDistance = (json['distance'] as num).toDouble();
    }

    return LoungeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      distance: calculatedDistance,
      pricePerHour: (json['price_per_hour'] as num?)?.toDouble() ?? 0.0,
      isOpen: json['is_open'] ?? true,
      location: json['location']?.toString(),
      city: json['city']?.toString(),
      totalReviews: (json['total_reviews'] as num?)?.toInt(),
      availableRooms: (json['available_rooms'] as num?)?.toInt(),
      descriptionAr: json['description_ar']?.toString(),
      descriptionEn: json['description_en']?.toString(),
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      opensAt: json['opens_at']?.toString() ?? '',
      closesAt: json['closes_at']?.toString() ?? '',
      mapsLink: json['maps_link']?.toString(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      categoryIcons: json['category_icons'] != null ? List<String>.from(json['category_icons']) : [],
      categoryId: json['category_id']?.toString(),
      ownerName: json['owner_name']?.toString(),
      ownerEmail: json['owner_email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'image_url': imageUrl,
      'is_open': isOpen,
      'location': location,
      'city': city,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'images': images,
      'opens_at': opensAt,
      'closes_at': closesAt,
      'maps_link': mapsLink,
      'lat': lat,
      'lng': lng,
      if (categoryId != null) 'category_id': categoryId,
    };
  }
}
