import '../../domain/entities/extra_entity.dart';

class ExtraModel extends ExtraEntity {
  const ExtraModel({
    required super.id,
    required super.loungeId,
    required super.name,
    required super.price,
    required super.category,
    super.iconKey,
    super.isOutOfStock,
  });

  factory ExtraModel.fromJson(Map<String, dynamic> json) {
    return ExtraModel(
      id: json['id']?.toString() ?? '',
      loungeId: json['lounge_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: json['category']?.toString() ?? 'Others',
      iconKey: json['icon_key']?.toString(),
      // The backend uses 'is_available', so we invert it for 'isOutOfStock'
      isOutOfStock: json['is_available'] == false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lounge_id': loungeId,
      'name': name,
      'price': price,
      'category': category,
      'icon_key': iconKey,
      'is_available': !isOutOfStock,
    };
  }
}
