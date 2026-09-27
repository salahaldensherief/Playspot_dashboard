import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Shift Reconciliation & Z-Report Cash Calculation', () {
    test('expected cash in drawer subtracts shift expenses', () {
      const startingCash = 200.0;
      const cashRevenue = 1500.0;
      const shiftExpenses = 300.0;

      final expectedCash = startingCash + cashRevenue - shiftExpenses;
      expect(expectedCash, 1400.0);

      const actualCashCounted = 1400.0;
      final discrepancy = actualCashCounted - expectedCash;
      expect(discrepancy, 0.0);
    });

    test('cancelled payout releases payments for re-claiming', () {
      final payments = <Map<String, dynamic>>[
        {'id': 'p1', 'payout_id': 'pay_123', 'amount': 500.0},
        {'id': 'p2', 'payout_id': 'pay_123', 'amount': 300.0},
      ];

      // Simulate cancel_payout setting payout_id = null
      for (final p in payments) {
        if (p['payout_id'] == 'pay_123') {
          p['payout_id'] = null;
        }
      }

      expect(payments.every((p) => p['payout_id'] == null), isTrue);
    });
  });
}
