import 'package:equatable/equatable.dart';

class ExtraEntity extends Equatable {
  final String id;
  final String loungeId;
  final String name;
  final double price;
  final String category; // e.g., Drinks, Snacks
  final String? iconKey;
  final bool isOutOfStock;
  final String? imageUrl;

  const ExtraEntity({
    required this.id,
    required this.loungeId,
    required this.name,
    required this.price,
    required this.category,
    this.iconKey,
    this.isOutOfStock = false,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [id, loungeId, name, price, category, iconKey, isOutOfStock, imageUrl];
}
