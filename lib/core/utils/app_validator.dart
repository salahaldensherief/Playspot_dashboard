import 'package:easy_localization/easy_localization.dart';

class AppValidator {
  static String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'field_required'.tr();
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'field_required'.tr();
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'invalid_email'.tr();
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'field_required'.tr();
    }
    if (value.length < 6) {
      return 'password_too_short'.tr();
    }
    return null;
  }

  static String? validateNumber(String? value, {bool allowNegative = false}) {
    if (value == null || value.trim().isEmpty) {
      return 'field_required'.tr();
    }
    final numValue = double.tryParse(value);
    if (numValue == null) {
      return 'invalid_number'.tr();
    }
    if (!allowNegative && numValue < 0) {
      return 'cannot_be_negative'.tr();
    }
    return null;
  }

  static String? validateOptionalNumber(String? value, {bool allowNegative = false}) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return validateNumber(value, allowNegative: allowNegative);
  }
}
