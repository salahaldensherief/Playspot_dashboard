import 'package:equatable/equatable.dart';

String roomSpaceTypeKey(String? name) {
  return switch (name?.trim().toLowerCase()) {
    'open' || 'open_area' => 'open_area',
    'private' || 'standard' || 'standard_room' => 'standard_room',
    'vip' || 'vip_room' => 'vip_room',
    _ => name?.trim().toLowerCase() ?? '',
  };
}

class RoomSpaceType extends Equatable {
  final String id;
  final String name;
  final String label;
  const RoomSpaceType({
    required this.id,
    required this.name,
    required this.label,
  });
  String get categoryKey => roomSpaceTypeKey(name);
  @override
  List<Object> get props => [id, name, label];
}
