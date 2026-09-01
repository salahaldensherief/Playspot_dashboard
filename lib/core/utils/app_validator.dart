import 'package:easy_localization/easy_localization.dart';
import '../../art_core/app_strings.dart';

class AppValidator {
  /// Validates that the field is not empty.
  static String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    return null;
  }

  /// Validates an email address.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return AppStrings.invalidEmail;
    }
    return null;
  }

  /// Validates password length and complexity if needed.
  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (value.length < minLength) {
      return AppStrings.passwordTooShort;
    }
    return null;
  }

  /// Validates that the password confirmation matches the password.
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (value != password) {
      // Note: You might want to add a specific string for 'passwords_do_not_match'
      return 'passwords_do_not_match'.tr();
    }
    return null;
  }

  /// Validates a number, optionally checking for negative values.
  static String? validateNumber(String? value, {bool allowNegative = false, double? min, double? max}) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    final numValue = double.tryParse(value);
    if (numValue == null) {
      return AppStrings.invalidNumber;
    }
    if (!allowNegative && numValue < 0) {
      return AppStrings.cannotBeNegative;
    }
    if (min != null && numValue < min) {
      return 'value_too_small'.tr(args: [min.toString()]);
    }
    if (max != null && numValue > max) {
      return 'value_too_large'.tr(args: [max.toString()]);
    }
    return null;
  }

  /// Validates a price (essentially a positive number).
  static String? validatePrice(String? value) {
    return validateNumber(value, allowNegative: false, min: 0);
  }

  /// Validates a phone number (Generic or Egyptian format).
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    // Generic phone regex or specific Egyptian format: 01xxxxxxxxx
    final phoneRegex = RegExp(r'^(01)[0-2,5]{1}[0-9]{8}$'); 
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'invalid_phone_number'.tr();
    }
    return null;
  }

  /// Validates that a string has a minimum length.
  static String? validateMinLength(String? value, int min) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (value.trim().length < min) {
      return 'too_short'.tr(args: [min.toString()]);
    }
    return null;
  }

  /// Validates a URL.
  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    );
    if (!urlRegex.hasMatch(value.trim())) {
      return 'invalid_url'.tr();
    }
    return null;
  }

  /// Helper for optional fields that still need specific format if not empty.
  static String? validateOptional(String? value, String? Function(String?) validator) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return validator(value);
  }

  /// Validates an optional number.
  static String? validateOptionalNumber(String? value, {bool allowNegative = false}) {
    return validateOptional(value, (val) => validateNumber(val, allowNegative: allowNegative));
  }
}
