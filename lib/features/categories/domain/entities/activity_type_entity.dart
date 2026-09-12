import 'package:equatable/equatable.dart';

class ActivityTypeEntity extends Equatable {
  final String id;
  final String name;
  final String label;
  final int sortOrder;

  const ActivityTypeEntity({
    required this.id,
    required this.name,
    required this.label,
    this.sortOrder = 0,
  });

  @override
  List<Object?> get props => [id, name, label, sortOrder];
}
