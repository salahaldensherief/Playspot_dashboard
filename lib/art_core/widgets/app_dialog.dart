import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:play_spot_dashboard/art_core/theme/app_colors.dart';
import 'app_button.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final double? width;
  final double? maxWidth;
  final bool showCloseIcon;
  final IconData? icon;

  const AppDialog({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.width,
    this.maxWidth,
    this.showCloseIcon = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    EasyLocalization.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final targetWidth = width ?? 600.w;
    final dialogWidth = math.min(targetWidth, screenSize.width - 32);

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(28.r, 24.r, 28.r, 16.r),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 22.sp),
                    ),
                    SizedBox(width: 12.w),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                  if (showCloseIcon)
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Flexible(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 28.r, vertical: 20.r),
                  child: child,
                ),
              ),
            ),
            if (actions != null && (actions?.isNotEmpty ?? false)) ...[
              const Divider(height: 1, color: AppColors.divider),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.r, vertical: 16.r),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: actions ?? const []),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    List<Widget>? actions,
    double? width,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) =>
          AppDialog(title: title, width: width, actions: actions, child: child),
    );
  }

  /// Shows a standardized confirmation dialog.
  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        content: Text(
          message,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16.sp),
        ),
        actions: [
          AppButton(
            text: cancelText ?? 'cancel'.tr(),
            variant: AppButtonVariant.outlined,
            onPressed: () => Navigator.pop(context, false),
          ),
          SizedBox(width: 12.w),
          AppButton(
            text: confirmText ?? 'confirm'.tr(),
            backgroundColor: confirmColor,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }
}
