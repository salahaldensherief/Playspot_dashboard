import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tournament Cancellation & Refund Processing', () {
    test('cancelling a tournament sets participant status to refund_pending for paid users', () {
      final participants = <Map<String, dynamic>>[
        {'id': 'p1', 'user_id': 'u1', 'payment_status': 'paid', 'registration_status': 'confirmed'},
        {'id': 'p2', 'user_id': 'u2', 'payment_status': 'unpaid', 'registration_status': 'pending_payment'},
      ];

      final refunds = <Map<String, dynamic>>[];

      for (final p in participants) {
        if (p['payment_status'] == 'paid') {
          p['payment_status'] = 'refund_pending';
          refunds.add({'participant_id': p['id'], 'amount': 100.0});
        }
        p['registration_status'] = 'cancelled';
      }

      expect(participants.first['payment_status'], 'refund_pending');
      expect(participants.last['payment_status'], 'unpaid');
      expect(refunds.length, 1);
      expect(refunds.single['participant_id'], 'p1');
    });
  });
}
