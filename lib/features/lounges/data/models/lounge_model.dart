import 'dart:math' as math;
import '../../domain/entities/lounge.dart';

class LoungeModel extends Lounge {
  const LoungeModel({
    required super.id,
    required super.name,
    required super.imageUrl,
    super.rating = 0.0,
    super.distance,
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
    double? parseDoubleNullable(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    double parseDouble(dynamic value) {
      return parseDoubleNullable(value) ?? 0.0;
    }

    // Helper to parse int safely
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    // Parse lat and lng
    double? lat = parseDoubleNullable(json['lat']) ?? parseDoubleNullable(json['latitude']);
    double? lng = parseDoubleNullable(json['lng']) ?? parseDoubleNullable(json['longitude']);

    // Parse location_point if lat/lng are missing
    if ((lat == null || lng == null) && json['location_point'] != null) {
      final locPoint = json['location_point'];
      if (locPoint is Map && locPoint['coordinates'] is List) {
        final coords = locPoint['coordinates'] as List;
        if (coords.length >= 2) {
          lng ??= parseDoubleNullable(coords[0]);
          lat ??= parseDoubleNullable(coords[1]);
        }
      } else if (locPoint is String) {
        final match = RegExp(r'POINT\s*\(\s*([-\d.]+)\s+([-\d.]+)\s*\)', caseSensitive: false)
            .firstMatch(locPoint);
        if (match != null) {
          lng ??= double.tryParse(match.group(1) ?? '');
          lat ??= double.tryParse(match.group(2) ?? '');
        }
      }
    }

    // Calculate or parse distance dynamically
    double? calculatedDistance;
    if (json['dist_meters'] != null) {
      calculatedDistance = parseDouble(json['dist_meters']) / 1000.0;
    } else {
      // Check if user/device coordinates are passed in json for dynamic calculation
      final deviceLat = parseDoubleNullable(json['device_lat']) ?? parseDoubleNullable(json['user_lat']);
      final deviceLng = parseDoubleNullable(json['device_lng']) ?? parseDoubleNullable(json['user_lng']);
      if (deviceLat != null && deviceLng != null && lat != null && lng != null) {
        const double earthRadiusKm = 6371.0;
        final dLat = (lat - deviceLat) * (math.pi / 180.0);
        final dLng = (lng - deviceLng) * (math.pi / 180.0);
        final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
            math.cos(deviceLat * (math.pi / 180.0)) *
                math.cos(lat * (math.pi / 180.0)) *
                math.sin(dLng / 2) *
                math.sin(dLng / 2);
        final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
        calculatedDistance = earthRadiusKm * c;
      }
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
      opensAt: json['opening_time']?.toString() ?? '',
      closesAt: json['closing_time']?.toString() ?? '',
      lat: lat,
      lng: lng,
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
      if (lat != null && lng != null) 'location_point': 'POINT($lng $lat)',
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

