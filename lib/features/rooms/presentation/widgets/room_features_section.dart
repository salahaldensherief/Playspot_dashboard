import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import '../../../categories/domain/entities/activity_type_entity.dart';

class RoomFeaturesSection extends StatefulWidget {
  final List<String> featuresAr;
  final List<String> featuresEn;
  final List<String> selectedActivityIds;
  final List<ActivityTypeEntity> activitiesList;
  final void Function(String en, String ar) onAddFeature;
  final void Function(int index) onRemoveFeature;
  final void Function(String tag) onToggleTag;

  const RoomFeaturesSection({
    super.key,
    required this.featuresAr,
    required this.featuresEn,
    required this.selectedActivityIds,
    required this.activitiesList,
    required this.onAddFeature,
    required this.onRemoveFeature,
    required this.onToggleTag,
  });

  @override
  State<RoomFeaturesSection> createState() => _RoomFeaturesSectionState();
}

class _RoomFeaturesSectionState extends State<RoomFeaturesSection> {
  final TextEditingController _featureArController = TextEditingController();
  final TextEditingController _featureEnController = TextEditingController();

  @override
  void dispose() {
    _featureArController.dispose();
    _featureEnController.dispose();
    super.dispose();
  }

  List<String> _getSuggestions() {
    final List<String> suggestions = [];
    String firstActivityName = '';
    if (widget.selectedActivityIds.isNotEmpty && widget.activitiesList.isNotEmpty) {
      final String targetId = widget.selectedActivityIds.first;
      ActivityTypeEntity? foundActivity;
      for (int i = 0; i < widget.activitiesList.length; i++) {
        if (widget.activitiesList[i].id == targetId) {
          foundActivity = widget.activitiesList[i];
          break;
        }
      }
      final activity = foundActivity ?? widget.activitiesList.first;
      firstActivityName = activity.label.toLowerCase();
    }

    if (firstActivityName.contains('simulator')) {
      suggestions.addAll(['Force Feedback', 'Direct Drive', 'Load Cell Pedals', 'Bucket Seat', 'Triple Monitor']);
    } else if (firstActivityName.contains('vr')) {
      suggestions.addAll(['Meta Quest 3', 'Valve Index', 'Wireless', 'Pro Controllers', 'Pico 4']);
    } else if (firstActivityName.contains('pc')) {
      suggestions.addAll(['RTX 4080', 'RTX 4090', 'Mechanical Keyboard', 'Gaming Mouse', '240Hz Monitor']);
    } else {
      suggestions.addAll(['PS5', 'PS4 Pro', 'DualSense Edge', '4K TV', 'Home Theater']);
    }
    return suggestions;
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _getSuggestions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.specs,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 12.h),
        if (suggestions.isNotEmpty) ...[
          Text(
            'Suggested Tags:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11.sp),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: suggestions.map((s) {
              final isAdded = widget.featuresEn.contains(s);
              return ActionChip(
                label: Text(
                  s,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: isAdded ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                backgroundColor: isAdded
                    ? AppColors.neonBlue.withValues(alpha: 0.5)
                    : AppColors.mutedBackground,
                onPressed: () => widget.onToggleTag(s),
              );
            }).toList(),
          ),
          SizedBox(height: 16.h),
        ],
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _featureArController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: AppStrings.nameAr,
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.mutedBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: TextFormField(
                controller: _featureEnController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: AppStrings.nameEn,
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.mutedBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            IconButton(
              onPressed: () {
                if (_featureArController.text.isNotEmpty && _featureEnController.text.isNotEmpty) {
                  widget.onAddFeature(_featureEnController.text, _featureArController.text);
                  _featureArController.clear();
                  _featureEnController.clear();
                }
              },
              icon: const Icon(Icons.add_circle, color: AppColors.neonBlue),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: List.generate(widget.featuresEn.length, (index) {
            return Chip(
              label: Text(
                '${widget.featuresEn[index]} | ${widget.featuresAr[index]}',
                style: TextStyle(fontSize: 11.sp),
              ),
              backgroundColor: AppColors.mutedBackground,
              deleteIcon: Icon(Icons.close, size: 14.r, color: AppColors.danger),
              onDeleted: () => widget.onRemoveFeature(index),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.r),
                side: const BorderSide(color: AppColors.borderDefault),
              ),
            );
          }),
        ),
      ],
    );
  }
}
