import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final double? fontSize;
  final String? hintText;
  final String? initialValue;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool readOnly;
  final bool enabled;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final Widget? suffix;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;
  final EdgeInsetsGeometry? contentPadding;
  final TextInputAction? textInputAction;
  final TextAlign textAlign;
  final Color? fillColor;

  final String? labelText;
  final int? maxLength;
  final int? minLines;

  const AppTextField({
    super.key,
    this.label = '',
    this.labelText,
    this.fontSize,
    this.hintText,
    this.initialValue,
    this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.readOnly = false,
    this.enabled = true,
    this.prefixIcon,
    this.prefixWidget,
    this.suffix,
    this.onTap,
    this.onChanged,
    this.onFieldSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.contentPadding,
    this.textInputAction,
    this.textAlign = TextAlign.start,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = labelText ?? label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (effectiveLabel.isNotEmpty) ...[
          Text(
            effectiveLabel,
            style: TextStyle(
              color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: fontSize ?? 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
        ],
        TextFormField(
          initialValue: controller == null ? initialValue : null,
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          readOnly: readOnly,
          enabled: enabled,
          focusNode: focusNode,
          autofocus: autofocus,
          textInputAction: textInputAction,
          textAlign: textAlign,
          onTap: onTap,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          style: TextStyle(
            color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: fontSize ?? 14.sp,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.textSecondary,
              fontSize: fontSize ?? 14.sp,
            ),
            prefixIcon: prefixWidget ??
                (prefixIcon != null
                    ? Icon(prefixIcon, color: AppColors.textSecondary, size: 20.r)
                    : null),
            suffixIcon: suffix,
            filled: true,
            fillColor: fillColor ??
                (enabled
                    ? AppColors.mutedBackground
                    : AppColors.cardBackground.withAlpha(128)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppColors.borderDefault),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: AppColors.borderDefault.withAlpha(128),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppColors.neonBlue),
            ),
            contentPadding: contentPadding ??
                EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
          ),
        ),
      ],
    );
  }
}
