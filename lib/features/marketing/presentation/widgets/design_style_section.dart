import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'package:play_spot_dashboard/art_core/widgets/app_text.dart';
import 'package:play_spot_dashboard/art_core/widgets/section_container.dart';

class DesignStyleSection extends StatelessWidget {
  final List<List<Color>> colorTemplates;
  final int selectedTemplate;
  final Function(int) onTemplateSelected;
  final String selectedIcon;
  final Function(String?) onIconChanged;

  const DesignStyleSection({
    super.key,
    required this.colorTemplates,
    required this.selectedTemplate,
    required this.onTemplateSelected,
    required this.selectedIcon,
    required this.onIconChanged,
  });

  static const Map<String, IconData> _iconMap = {
    'Flash': Icons.bolt_rounded,
    'Star': Icons.star_rounded,
    'Gift': Icons.card_giftcard_rounded,
    'Hot': Icons.local_fire_department_rounded,
    'Offer': Icons.local_offer_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: 'تصميم العرض والهوية البصرية (Design Style)',
      children: [
        AppText.subHeading('قالب الألوان (Color Palette):', fontSize: 13.sp, color: AppColors.textPrimary),
        SizedBox(height: 10.h),
        Row(
          children: List.generate(colorTemplates.length, (index) {
            final isSelected = selectedTemplate == index;
            return GestureDetector(
              onTap: () => onTemplateSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: 14.w),
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colorTemplates[index]),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: isSelected ? 2.5 : 0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colorTemplates[index].first.withValues(alpha: 0.6),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: isSelected ? Icon(Icons.check_rounded, color: Colors.white, size: 22.r) : null,
              ),
            );
          }),
        ),
        SizedBox(height: 20.h),
        AppText.subHeading('أيقونة العرض (Promo Icon):', fontSize: 13.sp, color: AppColors.textPrimary),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: _iconMap.entries.map((entry) {
            final isSelected = selectedIcon == entry.key || (selectedIcon == 'local_offer' && entry.key == 'Offer');
            return ChoiceChip(
              avatar: Icon(
                entry.value,
                size: 16.r,
                color: isSelected ? AppColors.neonPurple : AppColors.textSecondary,
              ),
              label: Text(
                entry.key,
                style: TextStyle(
                  color: isSelected ? AppColors.neonPurple : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12.sp,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onIconChanged(entry.key),
              selectedColor: AppColors.neonPurple.withValues(alpha: 0.2),
              backgroundColor: AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
                side: BorderSide(
                  color: isSelected ? AppColors.neonPurple : AppColors.borderDefault,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
