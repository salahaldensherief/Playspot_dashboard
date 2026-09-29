import '../../domain/entities/canteen_combo_entity.dart';
import 'canteen_combo_component_model.dart';

class CanteenComboModel extends CanteenComboEntity {
  const CanteenComboModel({
    required super.id,
    required super.loungeId,
    required super.nameAr,
    super.nameEn,
    super.descriptionAr,
    super.descriptionEn,
    super.imageUrl,
    required super.price,
    super.daysOfWeek,
    super.availableFrom,
    super.availableTo,
    super.validFrom,
    super.validTo,
    super.isActive = true,
    super.sortOrder = 0,
    super.items = const [],
  });

  factory CanteenComboModel.fromJson(Map<String, dynamic> json) {
    List<int>? parsedDays;
    if (json['days_of_week'] is List) {
      parsedDays = (json['days_of_week'] as List)
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .toList();
    }

    final rawValidFrom = json['valid_from'];
    final rawValidTo = json['valid_to'];

    List<CanteenComboComponentModel> parsedItems = [];
    final rawItems = json['canteen_combo_items'] ?? json['items'];
    if (rawItems is List) {
      parsedItems = rawItems
          .whereType<Map<String, dynamic>>()
          .map((item) => CanteenComboComponentModel.fromJson(item))
          .toList();
    }

    return CanteenComboModel(
      id: (json['id'] ?? '').toString(),
      loungeId: (json['lounge_id'] ?? '').toString(),
      nameAr: (json['name_ar'] ?? '').toString(),
      nameEn: json['name_en']?.toString(),
      descriptionAr: json['description_ar']?.toString(),
      descriptionEn: json['description_en']?.toString(),
      imageUrl: json['image_url']?.toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      daysOfWeek: parsedDays,
      availableFrom: json['available_from']?.toString(),
      availableTo: json['available_to']?.toString(),
      validFrom: rawValidFrom != null ? DateTime.tryParse(rawValidFrom.toString()) : null,
      validTo: rawValidTo != null ? DateTime.tryParse(rawValidTo.toString()) : null,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      items: parsedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.isNotEmpty ? id : null,
      'lounge_id': loungeId,
      'name_ar': nameAr,
      'name_en': nameEn,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'image_url': imageUrl,
      'price': price,
      'days_of_week': daysOfWeek,
      'available_from': availableFrom,
      'available_to': availableTo,
      'valid_from': validFrom?.toIso8601String().split('T').first,
      'valid_to': validTo?.toIso8601String().split('T').first,
      'is_active': isActive,
      'sort_order': sortOrder,
    }..removeWhere((key, value) => value == null && key == 'id');
  }
}
