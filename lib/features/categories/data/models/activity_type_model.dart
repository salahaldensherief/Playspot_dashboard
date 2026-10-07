
import 'package:play_spot_dashboard/features/categories/domain/entities/activity_type_entity.dart';

class ActivityTypeModel extends ActivityTypeEntity {
  const ActivityTypeModel({
    required super.id,
    required super.name,
    required super.label,
    super.sortOrder = 0,
    super.category = 'other',
    super.iconName = 'category',
    super.pricingModel = 'per_room_hour',
    super.requiresScreen = false,
    super.requiresControllers = false,
  });

  factory ActivityTypeModel.fromJson(Map<String, dynamic> json) {
    return ActivityTypeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      sortOrder: json['sort_order'] ?? 0,
      category: json['category']?.toString() ?? 'other',
      iconName: json['icon_name']?.toString() ?? 'category',
      pricingModel: json['pricing_model']?.toString() ?? 'per_room_hour',
      requiresScreen: json['requires_screen'] as bool? ?? false,
      requiresControllers: json['requires_controllers'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'name': name,
      'label': label,
      'sort_order': sortOrder,
      'category': category,
      'icon_name': iconName,
      'pricing_model': pricingModel,
      'requires_screen': requiresScreen,
      'requires_controllers': requiresControllers,
    };
  }

  Map<String, dynamic> toCacheJson() {
    return {
      ...toJson(),
      'category': category,
      'icon_name': iconName,
      'pricing_model': pricingModel,
      'requires_screen': requiresScreen,
      'requires_controllers': requiresControllers,
    };
  }
}
