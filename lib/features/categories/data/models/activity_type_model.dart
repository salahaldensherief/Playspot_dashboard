import '../entities/activity_type_entity.dart';

class ActivityTypeModel extends ActivityTypeEntity {
  const ActivityTypeModel({
    required super.id,
    required super.name,
    required super.label,
    super.sortOrder = 0,
  });

  factory ActivityTypeModel.fromJson(Map<String, dynamic> json) {
    return ActivityTypeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'label': label,
      'sort_order': sortOrder,
    };
  }
}
