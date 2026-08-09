import 'package:equatable/equatable.dart';

class Lounge extends Equatable {
  final String id;
  final String name;
  final String location;
  final double lat;
  final double lng;
  final String imageUrl;
  final String categoryId;
  final bool isOpen;

  const Lounge({
    required this.id,
    required this.name,
    required this.location,
    required this.lat,
    required this.lng,
    required this.imageUrl,
    required this.categoryId,
    this.isOpen = true,
  });

  @override
  List<Object?> get props => [id, name, location, lat, lng, imageUrl, categoryId, isOpen];
}
