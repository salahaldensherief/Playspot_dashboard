import 'package:flutter/material.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/custom_dropdown.dart';
import '../../domain/entities/room_space_type.dart';
import 'room_space_type_label.dart';

class RoomSpaceTypeSelector extends StatelessWidget {
  final List<RoomSpaceType> types;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  const RoomSpaceTypeSelector({
    super.key,
    required this.types,
    this.selectedId,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => CustomDropdown<String>(
    key: ValueKey(selectedId),
    label: AppStrings.spaceType,
    value: selectedId,
    items: types.map((type) => type.id).toList(),
    itemLabel: (id) {
      for (final type in types) {
        if (type.id == id) {
          return roomSpaceTypeLabel(type.name, fallback: type.label);
        }
      }
      return AppStrings.notAvailable;
    },
    validator: (_) => types.any((type) => type.id == selectedId)
        ? null
        : AppStrings.fieldRequired,
    onChanged: onChanged,
  );
}
