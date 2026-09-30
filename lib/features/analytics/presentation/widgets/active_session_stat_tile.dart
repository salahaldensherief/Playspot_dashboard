import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/widgets/app_text.dart';

class ActiveSessionStatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const ActiveSessionStatTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18.r, color: color),
        SizedBox(width: 8.w),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.body(title, fontSize: 10.sp, color: AppColors.textMuted),
            AppText.subHeading(
              value,
              fontSize: 13.sp,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ],
        )),
      ],
    );
  }
}
