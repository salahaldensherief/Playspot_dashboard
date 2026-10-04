import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/core/utils/app_validator.dart';

void main() {
  test('accepts long domain suffixes and plus addressing', () {
    for (final email in [
      'owner@example.invalid',
      'owner+branch@example.technology',
      'owner@sub.example.com',
    ]) {
      expect(AppValidator.validateEmail(email), isNull, reason: email);
    }
  });
  test(
    'rejects malformed addresses without accepting spaces or empty labels',
    () {
      for (final email in [
        '',
        'owner@example',
        'owner@@example.com',
        'owner name@example.com',
        'owner@example..com',
        'owner@-example.com',
        '.owner@example.com',
        'owner..name@example.com',
      ]) {
        expect(AppValidator.validateEmail(email), isNotNull, reason: email);
      }
    },
  );
}
