import 'package:equatable/equatable.dart';

class Lounge extends Equatable {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final double distance;
  final double pricePerHour;
  final bool isOpen;
  final String? location;
  final String? city;
  final int? totalReviews;
  final int? availableRooms;
  final String? descriptionAr;
  final String? descriptionEn;
  final List<String>? images;
  final String opensAt;
  final String closesAt;
  final double? lat;
  final double? lng;
  final List<String> categoryIcons;
  final String? categoryId;
  final String? ownerName;
  final String? ownerEmail;
  final String status;
  final bool hasDiscount;
  final int discountPercentage;
  final String? discountTitleAr;
  final String? discountTitleEn;
  final DateTime? discountExpiresAt;

  const Lounge({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.rating = 0.0,
    this.distance = 0.0,
    this.pricePerHour = 0.0,
    this.isOpen = true,
    this.location,
    this.city,
    this.totalReviews,
    this.availableRooms,
    this.descriptionAr,
    this.descriptionEn,
    this.images,
    required this.opensAt,
    required this.closesAt,
    this.lat,
    this.lng,
    this.categoryIcons = const [],
    this.categoryId,
    this.ownerName,
    this.ownerEmail,
    this.status = 'active',
    this.hasDiscount = false,
    this.discountPercentage = 0,
    this.discountTitleAr,
    this.discountTitleEn,
    this.discountExpiresAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        imageUrl,
        rating,
        distance,
        pricePerHour,
        isOpen,
        location,
        city,
        totalReviews,
        availableRooms,
        descriptionAr,
        descriptionEn,
        images,
        opensAt,
        closesAt,
        lat,
        lng,
        categoryIcons,
        categoryId,
        ownerName,
        ownerEmail,
        status,
        hasDiscount,
        discountPercentage,
        discountTitleAr,
        discountTitleEn,
        discountExpiresAt,
      ];

  Lounge copyWith({
    String? id,
    String? name,
    String? imageUrl,
    double? rating,
    double? distance,
    double? pricePerHour,
    bool? isOpen,
    String? location,
    String? city,
    int? totalReviews,
    int? availableRooms,
    String? descriptionAr,
    String? descriptionEn,
    List<String>? images,
    String? opensAt,
    String? closesAt,
    double? lat,
    double? lng,
    List<String>? categoryIcons,
    String? categoryId,
    String? ownerName,
    String? ownerEmail,
    String? status,
    bool? hasDiscount,
    int? discountPercentage,
    String? discountTitleAr,
    String? discountTitleEn,
    DateTime? discountExpiresAt,
  }) {
    return Lounge(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      distance: distance ?? this.distance,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      isOpen: isOpen ?? this.isOpen,
      location: location ?? this.location,
      city: city ?? this.city,
      totalReviews: totalReviews ?? this.totalReviews,
      availableRooms: availableRooms ?? this.availableRooms,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      images: images ?? this.images,
      opensAt: opensAt ?? this.opensAt,
      closesAt: closesAt ?? this.closesAt,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      categoryIcons: categoryIcons ?? this.categoryIcons,
      categoryId: categoryId ?? this.categoryId,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      status: status ?? this.status,
      hasDiscount: hasDiscount ?? this.hasDiscount,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountTitleAr: discountTitleAr ?? this.discountTitleAr,
      discountTitleEn: discountTitleEn ?? this.discountTitleEn,
      discountExpiresAt: discountExpiresAt ?? this.discountExpiresAt,
    );
  }
}
