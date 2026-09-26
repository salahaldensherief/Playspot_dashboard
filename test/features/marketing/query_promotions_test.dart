import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://tgpdexoitemmpruepgyt.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRncGRleG9pdGVtbXBydWVwZ3l0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2NjYyNzYsImV4cCI6MjA5NDI0MjI3Nn0.i5ekdw4CkWh97-BGWzCRQZ4c9bIKWIo2vD-Ev58BVC4';

void main() {
  test('Query real promotions in DB', () async {
    final client = SupabaseClient(
      supabaseUrl,
      supabaseAnonKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );

    try {
      final promos = await client.from('promotions').select('*').limit(10);
      debugPrint('📢 Real Promotions found in DB (${promos.length}):');
      for (var p in promos) {
        debugPrint('   Promo ID: ${p['id']}, Lounge ID: ${p['lounge_id']}, Title: ${p['title'] ?? p['title_ar']}');
      }

      final lounges = await client.from('lounges').select('id, name, owner_id').limit(10);
      debugPrint('🏢 Real Lounges found in DB (${lounges.length}):');
      for (var l in lounges) {
        debugPrint('   Lounge ID: ${l['id']}, Name: ${l['name']}, Owner ID: ${l['owner_id']}');
      }
    } catch (e) {
      debugPrint('🔴 Query error: $e');
    } finally {
      client.dispose();
    }
  });
}
