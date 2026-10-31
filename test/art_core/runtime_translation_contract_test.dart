import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final language in ['ar', 'en']) {
    test('runtime navigation and shift labels are strings in $language', () {
      final data =
          jsonDecode(
                File('assets/translations/$language.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      for (final key in [
        'shifts',
        'billing',
        'lounges',
        'menu',
        'operations',
        'reports',
        'reviews',
        'staff',
        'withdraw',
        'duration',
        'customer_info',
        'room',
        'payment_details',
      ]) {
        expect(
          data[key],
          isA<String>(),
          reason: 'Text widgets cannot render a namespace at $key',
        );
      }
      expect((data['cashier'] as Map)['label'], isA<String>());
      // Keeping the label must preserve the cashier feature's translation tree.
      expect((data['cashier'] as Map)['manage'], isA<String>());
    });
  }
}
