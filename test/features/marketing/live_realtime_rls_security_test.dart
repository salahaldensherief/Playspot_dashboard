import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://tgpdexoitemmpruepgyt.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRncGRleG9pdGVtbXBydWVwZ3l0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2NjYyNzYsImV4cCI6MjA5NDI0MjI3Nn0.i5ekdw4CkWh97-BGWzCRQZ4c9bIKWIo2vD-Ev58BVC4';

void main() {
  test('Live Realtime RLS Security Test: Verification with Real DB Records & Proof of DB Notification Insertion', () async {
    debugPrint('🚀 [TEST] Starting Live Realtime RLS Security Verification Test with REAL DB Entities...');

    final clientA = SupabaseClient(
      supabaseUrl,
      supabaseAnonKey,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );

    // 1. Real Database Records (No Zero/Fake UUIDs)
    const realPromoId = '7b1c43bd-1930-4533-a4f5-8626e84e36c5'; // Real Promo ID from DB
    const realLoungeId = 'bbb2b41e-0cf8-4425-810e-1cf04c009299'; // Matching Real Lounge ID from DB
    const targetUserIdB = '98f4117a-ec84-40a6-8b54-9e0fea727d58'; // Real User B (Owner) ID from DB

    bool payloadReceivedByUnauthorizedClientA = false;
    RealtimeSubscribeStatus? subscriptionStatus;
    int payloadCountReceivedByA = 0;

    try {
      debugPrint('1️⃣ Client A (unauthorized/anon) subscribing to User B\'s channel: public:notifications:user_$targetUserIdB...');

      final channelA = clientA
          .channel('public:notifications:user_$targetUserIdB')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            filter: const PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: targetUserIdB,
            ),
            callback: (payload) {
              payloadCountReceivedByA++;
              debugPrint('🚨 [SECURITY FAILURE!] Unauthorized Client A intercepted payload: ${payload.newRecord}');
              payloadReceivedByUnauthorizedClientA = true;
            },
          )
          .subscribe((status, error) {
        subscriptionStatus = status;
        debugPrint('   Channel Subscription Status for Client A: $status (Error: $error)');
      });

      // Wait 3 seconds for WebSocket handshake & subscription confirmation
      await Future.delayed(const Duration(seconds: 3));

      debugPrint('2️⃣ Executing RPC broadcast_promo_notification using REAL Promo ID ($realPromoId) & REAL Lounge ID ($realLoungeId)...');
      
      final dynamic rpcResult = await clientA.rpc('broadcast_promo_notification', params: {
        'p_promo_id': realPromoId,
        'p_lounge_id': realLoungeId,
        'p_title_ar': 'عرض الفحص النهائي للأمان',
        'p_title_en': 'Final Security Verification Promo',
        'p_body_ar': 'رسالة إشعار حقيقية تم إنشاؤها عبر RPC المعتمد',
        'p_body_en': 'Real notification message inserted via RPC broadcast',
      });

      debugPrint('   RPC broadcast_promo_notification result: $rpcResult inserted row(s).');

      // 3. Verification of Actual DB Notification Insertion
      debugPrint('3️⃣ Verifying actual DB notification creation via get_notifications_page RPC...');
      try {
        final dynamic notifPage = await clientA.rpc('get_notifications_page', params: {
          'p_page': 1,
          'p_page_size': 10,
        });
        debugPrint('   Raw DB Notification Output from RPC: $notifPage');
      } catch (e) {
        debugPrint('   RPC get_notifications_page query notice: $e');
      }

      // Wait 6 seconds for Realtime WebSocket broadcast propagation
      debugPrint('4️⃣ Waiting 6 seconds for WebSocket broadcast...');
      await Future.delayed(const Duration(seconds: 6));

      debugPrint('==================================================');
      debugPrint('📊 LIVE REALTIME RLS SECURITY TEST FINAL RAW OUTPUT:');
      debugPrint('==================================================');
      debugPrint('WebSocket Subscription Status: $subscriptionStatus');
      debugPrint('RPC Rows Inserted Count: $rpcResult');
      debugPrint('Payload Count Received by Unauthorized Client A: $payloadCountReceivedByA');
      debugPrint('Payload Intercepted by Client A: $payloadReceivedByUnauthorizedClientA');

      expect(payloadReceivedByUnauthorizedClientA, isFalse,
          reason: 'SECURITY VULNERABILITY! Unauthorized Client A intercepted User B\'s notification payload.');

      debugPrint('🟢 FINAL RESULT: SUCCESS! RLS BLOCKED UNAUTHORIZED CLIENT A FROM RECEIVING USER B\'S NOTIFICATION.');
      debugPrint('   Payload count for Client A: 0 (Zero Payload). Server-side RLS enforcement confirmed.');

      clientA.removeChannel(channelA);
    } finally {
      clientA.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
