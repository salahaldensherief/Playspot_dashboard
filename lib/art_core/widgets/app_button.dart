import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

enum AppButtonVariant { primary, gradient, outlined, danger, text }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? disabledBackgroundColor;
  final Color? disabledForegroundColor;
  final Gradient? gradient;
  final double? borderRadius;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height,
    this.backgroundColor,
    this.foregroundColor,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
    this.gradient,
    this.borderRadius,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bool isGradient = variant == AppButtonVariant.gradient;
    final bool isPrimary = variant == AppButtonVariant.primary;
    final bool isDanger = variant == AppButtonVariant.danger;
    final bool isOutlined = variant == AppButtonVariant.outlined;
    final bool isText = variant == AppButtonVariant.text;

    final Color effectiveBg = backgroundColor ??
        (isPrimary
            ? AppColors.neonBlue
            : isDanger
                ? AppColors.danger
                : Colors.transparent);

    final Color effectiveFg = foregroundColor ??
        (isPrimary || isDanger || isGradient
            ? Colors.white
            : isText
                ? AppColors.neonBlue
                : AppColors.textPrimary);

    final double effectiveRadius = borderRadius ?? 8.r;

    Widget buttonContent = isLoading
        ? SizedBox(
            height: 20.r,
            width: 20.r,
            child: CircularProgressIndicator(strokeWidth: 2, color: effectiveFg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) Icon(icon, size: 18.r, color: effectiveFg),
              if (icon != null) SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: effectiveFg,
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize ?? 14.sp,
                  ),
                ),
              ),
            ],
          );

    if (isGradient) {
      final Gradient effectiveGradient = gradient ??
          const LinearGradient(
            colors: [AppColors.neonBlue, AppColors.neonPurple],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          );

      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Container(
          width: width,
          height: height ?? 48.h,
          decoration: BoxDecoration(
            gradient: onPressed == null || isLoading ? null : effectiveGradient,
            color: onPressed == null || isLoading
                ? (disabledBackgroundColor ?? AppColors.cardBackground)
                : null,
            borderRadius: BorderRadius.circular(effectiveRadius),
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: padding ?? EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              minimumSize: Size(width ?? 0, height ?? 48.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(effectiveRadius),
              ),
            ),
            child: buttonContent,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBg,
          foregroundColor: effectiveFg,
          disabledBackgroundColor: disabledBackgroundColor ?? AppColors.cardBackground,
          disabledForegroundColor: disabledForegroundColor ?? AppColors.textMuted,
          padding: padding ?? (height != null ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h)),
          minimumSize: Size(width ?? 0, height ?? 48.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(effectiveRadius),
            side: isOutlined
                ? const BorderSide(color: AppColors.borderDefault)
                : BorderSide.none,
          ),
          elevation: 0,
        ),
        child: buttonContent,
      ),
    );
  }
}
