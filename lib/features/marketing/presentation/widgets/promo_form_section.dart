import 'package:flutter/material.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text_field.dart';
import 'package:play_spot_dashboard/art_core/widgets/custom_dropdown.dart';
import 'package:play_spot_dashboard/art_core/widgets/section_container.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';
import 'package:play_spot_dashboard/features/rooms/domain/entities/room_entity.dart';

class PromoFormSection extends StatelessWidget {
  final String selectedDeepLink;
  final Function(String?) onDeepLinkChanged;
  final DateTime? expiresAt;
  final Function(DateTime) onDateChanged;
  final String? selectedTag;
  final Function(String?) onTagChanged;
  final bool isRoomSpecific;
  final Function(bool) onRoomSpecificChanged;
  final String? selectedRoomId;
  final Function(String?) onRoomChanged;
  final List<RoomEntity> availableRooms;
  final TextEditingController titleArController;
  final TextEditingController titleEnController;
  final TextEditingController expirationDateController;

  const PromoFormSection({
    super.key,
    required this.selectedDeepLink,
    required this.onDeepLinkChanged,
    this.expiresAt,
    required this.onDateChanged,
    this.selectedTag,
    required this.onTagChanged,
    required this.isRoomSpecific,
    required this.onRoomSpecificChanged,
    this.selectedRoomId,
    required this.onRoomChanged,
    required this.availableRooms,
    required this.titleArController,
    required this.titleEnController,
    required this.expirationDateController,
  });

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: AppStrings.promotionsMarketing,
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: titleArController,
                label: AppStrings.promoTitleAr,
                hintText: AppStrings.promoTitleArHint,
                validator: AppValidator.validateRequired,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppTextField(
                controller: titleEnController,
                label: AppStrings.promoTitleEn,
                hintText: AppStrings.promoTitleEnHint,
                validator: AppValidator.validateRequired,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomDropdown<String>(
                label: AppStrings.tagCategory,
                value: selectedTag,
                items: const ['Offer', 'Event', 'Tournament', 'New'],
                itemLabel: (s) => s,
                onChanged: onTagChanged,
                validator: (v) => v == null ? AppStrings.fieldRequired : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: expiresAt ?? DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) onDateChanged(date);
                },
                child: AppTextField(
                  label: AppStrings.expirationDate,
                  hintText: 'YYYY-MM-DD',
                  enabled: false,
                  controller: expirationDateController,
                  validator: AppValidator.validateRequired,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: isRoomSpecific,
              onChanged: (v) => onRoomSpecificChanged(v ?? false),
            ),
            Text(AppStrings.roomSpecific),
            if (isRoomSpecific) ...[
              const SizedBox(width: 16),
              Expanded(
                child: CustomDropdown<String>(
                  label: AppStrings.selectRoom,
                  value: selectedRoomId,
                  items: availableRooms.map((room) => room.id).toList(),
                  itemLabel: (id) {
                    final room = availableRooms.cast<RoomEntity?>().firstWhere(
                      (r) => r?.id == id,
                      orElse: () => null,
                    );
                    return room?.nameEn ?? 'Unknown Room';
                  },
                  onChanged: onRoomChanged,
                  validator: (v) => isRoomSpecific && v == null ? AppStrings.fieldRequired : null,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        CustomDropdown<String>(
          label: AppStrings.deepLinkDest,
          value: selectedDeepLink,
          items: const ['Specific Room', 'Lounge Profile', 'External Link'],
          itemLabel: (s) => s,
          onChanged: onDeepLinkChanged,
        ),
      ],
    );
  }
}
