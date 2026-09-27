import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Loyalty & Points Deduplication Guard', () {
    test('points awarded only once per booking ID', () {
      final transactions = <Map<String, dynamic>>[];
      const bookingId = 'booking_abc_123';

      void awardPoints(String id, int pts) {
        final exists = transactions.any((t) => t['reference_id'] == id && t['type'] == 'earn');
        if (!exists) {
          transactions.add({'reference_id': id, 'points': pts, 'type': 'earn'});
        }
      }

      awardPoints(bookingId, 15);
      awardPoints(bookingId, 15); // duplicate attempt

      expect(transactions.length, 1);
      expect(transactions.single['points'], 15);
    });

    test('admin point adjustment creates transaction log entry', () {
      final transactions = <Map<String, dynamic>>[];
      int userPoints = 100;

      void adjustPoints(int change, String reason) {
        userPoints += change;
        transactions.add({
          'points': change,
          'type': change > 0 ? 'admin_grant' : 'admin_deduct',
          'description': reason,
        });
      }

      adjustPoints(50, 'Bonus points from admin');
      expect(userPoints, 150);
      expect(transactions.length, 1);
      expect(transactions.first['type'], 'admin_grant');
    });
  });
}
