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
  final String? mapsLink;
  final double? lat;
  final double? lng;
  final List<String> categoryIcons;
  final String? categoryId;
  final String? ownerName;
  final String? ownerEmail;

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
    this.mapsLink,
    this.lat,
    this.lng,
    this.categoryIcons = const [],
    this.categoryId,
    this.ownerName,
    this.ownerEmail,
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
        mapsLink,
        lat,
        lng,
        categoryIcons,
        categoryId,
        ownerName,
        ownerEmail,
      ];
}
