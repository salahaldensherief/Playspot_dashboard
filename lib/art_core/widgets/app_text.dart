import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

class AppText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final String? fontFamily;

  const AppText(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.fontFamily,
  });

  const AppText.heading(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight = FontWeight.bold,
    this.color = AppColors.textPrimary,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : fontFamily = null;

  const AppText.subHeading(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight = FontWeight.w600,
    this.color = AppColors.textPrimary,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : fontFamily = null;

  const AppText.body(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight = FontWeight.normal,
    this.color = AppColors.textSecondary,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : fontFamily = null;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: fontSize ?? 14.sp,
        fontWeight: fontWeight,
        color: color ?? AppColors.textPrimary,
        fontFamily: fontFamily,
      ),
    );
  }
}
