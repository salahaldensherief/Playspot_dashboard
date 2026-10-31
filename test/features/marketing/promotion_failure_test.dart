import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/features/marketing/data/marketing_failure_mapper.dart';

void main() {
  test('actual missing promotion is distinguished from permission denial', () {
    expect(
      marketingFailure(
        const PostgrestException(message: 'Promotion not found', code: 'P0002'),
      ).message,
      'promotion_not_found',
    );
    expect(
      marketingFailure(
        const PostgrestException(message: 'Not authorized', code: '42501'),
      ).message,
      'promotion_permission_denied',
    );
  });
  test('unknown server exceptions are not exposed as user-facing SQL text', () {
    expect(
      marketingFailure(
        const PostgrestException(
          message: 'private internal details',
          code: 'XX000',
        ),
      ).message,
      'promotion_operation_failed',
    );
    expect(
      marketingFailure(Exception('fixture network failure')).message,
      'promotion_operation_failed',
    );
  });
}
