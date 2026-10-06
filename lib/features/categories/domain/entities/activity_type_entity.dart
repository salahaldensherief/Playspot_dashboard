import 'package:equatable/equatable.dart';

class ActivityTypeEntity extends Equatable {
  final String id;
  final String name;
  final String label;
  final int sortOrder;
  final String category;
  final String iconName;
  final String pricingModel;
  final bool requiresScreen;
  final bool requiresControllers;

  const ActivityTypeEntity({
    required this.id,
    required this.name,
    required this.label,
    this.sortOrder = 0,
    this.category = 'other',
    this.iconName = 'category',
    this.pricingModel = 'per_room_hour',
    this.requiresScreen = false,
    this.requiresControllers = false,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    label,
    sortOrder,
    category,
    iconName,
    pricingModel,
    requiresScreen,
    requiresControllers,
  ];
}
