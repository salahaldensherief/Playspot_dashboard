import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('open-time settings fail closed through the canonical RPC', () {
    final source = File(
      'lib/features/lounges/data/repositories/'
      'lounge_payment_settings_repository_impl.dart',
    ).readAsStringSync();

    expect(source, contains("rpc('update_lounge_open_time_policy'"));
    expect(
      source,
      isNot(contains('fallback to table update')),
    );
    expect(
      source,
      contains("updateData.remove('allow_open_time_sessions')"),
    );
  });
}
