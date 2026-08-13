import 'package:equatable/equatable.dart';

class ExtraEntity extends Equatable {
  final String id;
  final String loungeId;
  final String nameAr;
  final String nameEn;
  final String name; // Keeping for compatibility
  final double price;
  final String category; // e.g., Drinks, Snacks
  final String? iconKey;
  final bool isOutOfStock;
  final String? imageUrl;

  const ExtraEntity({
    required this.id,
    required this.loungeId,
    required this.nameAr,
    required this.nameEn,
    this.name = '',
    required this.price,
    required this.category,
    this.iconKey,
    this.isOutOfStock = false,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [id, loungeId, nameAr, nameEn, name, price, category, iconKey, isOutOfStock, imageUrl];
}
