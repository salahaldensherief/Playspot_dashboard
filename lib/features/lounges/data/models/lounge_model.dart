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
    super.lat,
    super.lng,
    super.categoryIcons = const [],
    super.categoryId,
    super.ownerName,
    super.ownerEmail,
    super.status = 'active',
    super.hasDiscount = false,
    super.discountPercentage = 0,
    super.discountTitleAr,
    super.discountTitleEn,
    super.discountExpiresAt,
  });

  factory LoungeModel.fromJson(Map<String, dynamic> json) {
    // Helper to parse double safely
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    // Helper to parse int safely
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    double calculatedDistance = 0.0;
    if (json['dist_meters'] != null) {
      calculatedDistance = parseDouble(json['dist_meters']) / 1000.0;
    } else if (json['distance'] != null) {
      calculatedDistance = parseDouble(json['distance']);
    }

    return LoungeModel(
      id: (json['id'] ?? json['lounge_id'])?.toString() ?? '',
      name: (json['name'] ?? json['lounge_name'])?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      rating: parseDouble(json['rating']),
      distance: calculatedDistance,
      pricePerHour: parseDouble(json['price_per_hour']),
      isOpen: json['is_open'] ?? true,
      location: json['location']?.toString(),
      city: json['city']?.toString(),
      totalReviews: parseInt(json['total_reviews']),
      availableRooms: parseInt(json['available_rooms'] ?? json['rooms_count']),
      descriptionAr: json['description_ar']?.toString(),
      descriptionEn: json['description_en']?.toString(),
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      opensAt: json['opening_time']?.toString() ?? json['opens_at']?.toString() ?? '',
      closesAt: json['closing_time']?.toString() ?? json['closes_at']?.toString() ?? '',
      lat: (json['latitude'] != null)
          ? parseDouble(json['latitude'])
          : ((json['lat'] != null) ? parseDouble(json['lat']) : null),
      lng: (json['longitude'] != null)
          ? parseDouble(json['longitude'])
          : ((json['lng'] != null) ? parseDouble(json['lng']) : null),
      categoryIcons: json['category_icons'] != null ? List<String>.from(json['category_icons']) : [],
      categoryId: json['category_id']?.toString(),
      ownerName: json['owner_name']?.toString(),
      ownerEmail: json['owner_email']?.toString(),
      status: json['status']?.toString() ?? 'active',
      hasDiscount: json['has_discount'] ?? false,
      discountPercentage: parseInt(json['discount_percentage']) ?? 0,
      discountTitleAr: json['discount_title_ar']?.toString(),
      discountTitleEn: json['discount_title_en']?.toString(),
      discountExpiresAt: json['discount_expires_at'] != null ? DateTime.parse(json['discount_expires_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'rating': rating,
      'distance': distance,
      'price_per_hour': pricePerHour,
      'is_open': isOpen,
      'location': location,
      'city': city,
      'total_reviews': totalReviews,
      'available_rooms': availableRooms,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'images': images,
      'opening_time': opensAt,
      'closing_time': closesAt,
      'latitude': lat,
      'longitude': lng,
      'opens_at': opensAt,
      'closes_at': closesAt,
      'lat': lat,
      'lng': lng,
      'status': status,
      'has_discount': hasDiscount,
      'discount_percentage': discountPercentage,
      'discount_title_ar': discountTitleAr,
      'discount_title_en': discountTitleEn,
      'discount_expires_at': discountExpiresAt?.toIso8601String(),
      if (categoryId != null) 'category_id': categoryId,
      if (ownerName != null) 'owner_name': ownerName,
      if (ownerEmail != null) 'owner_email': ownerEmail,
    };
  }
}
