import '../../domain/entities/room_space_type.dart';

class RoomSpaceTypeModel extends RoomSpaceType {
  const RoomSpaceTypeModel({
    required super.id,
    required super.name,
    required super.label,
  });
  factory RoomSpaceTypeModel.fromJson(Map<String, dynamic> json) =>
      RoomSpaceTypeModel(
        id: json['id'] as String,
        name: json['name'] as String,
        label: json['label'] as String? ?? json['name'] as String,
      );
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'label': label};
}
