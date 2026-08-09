import '../../domain/entities/lounge.dart';

class LoungeModel extends Lounge {
  const LoungeModel({
    required super.id,
    required super.name,
    required super.location,
    required super.lat,
    required super.lng,
    required super.imageUrl,
    required super.categoryId,
    super.isOpen,
  });

  factory LoungeModel.fromJson(Map<String, dynamic> json) {
    return LoungeModel(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      imageUrl: json['image_url'],
      categoryId: json['category_id'],
      isOpen: json['is_open'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'lat': lat,
      'lng': lng,
      'image_url': imageUrl,
      'category_id': categoryId,
      'is_open': isOpen,
    };
  }
}
