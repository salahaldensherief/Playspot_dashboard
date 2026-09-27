import 'package:flutter_test/flutter_test.dart';
import 'package:postgrest/postgrest.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://tgpdexoitemmpruepgyt.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRncGRleG9pdGVtbXBydWVwZ3l0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2NjYyNzYsImV4cCI6MjA5NDI0MjI3Nn0.i5ekdw4CkWh97-BGWzCRQZ4c9bIKWIo2vD-Ev58BVC4';

void main() {
  test('anonymous users cannot execute broadcast_promo_notification', () async {
    final client = SupabaseClient(
      supabaseUrl,
      supabaseAnonKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );

    try {
      await expectLater(
        client.rpc(
          'broadcast_promo_notification',
          params: const {
            'p_promo_id': '7b1c43bd-1930-4533-a4f5-8626e84e36c5',
            'p_lounge_id': 'bbb2b41e-0cf8-4425-810e-1cf04c009299',
            'p_title_ar': 'اختبار أمان',
            'p_title_en': 'Security test',
            'p_body_ar': 'يجب رفض هذا الطلب المجهول',
            'p_body_en': 'This anonymous request must be rejected',
          },
        ),
        throwsA(
          isA<PostgrestException>().having(
            (error) => error.code,
            'code',
            '42501',
          ),
        ),
      );
    } finally {
      client.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 1)));
}
