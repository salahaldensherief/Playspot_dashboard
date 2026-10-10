import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/widgets/shift_financial_summary_tab.dart';
import 'package:play_spot_dashboard/features/shifts/presentation/shift_management/widgets/shift_kpi_cards.dart';
import 'package:play_spot_dashboard/features/shifts/data/models/shift_model.dart';
import 'package:play_spot_dashboard/features/shifts/data/models/live_shift_overview_model.dart';

void main() {
  testWidgets(
    'masked financial summary and mixed KPIs do not show fabricated totals',
    (tester) async {
      final masked = ShiftModel.fromJson({
        'id': 'masked',
        'financials_visible': false,
        'actual_cash_counted': 130,
      });
      final visible = ShiftModel.fromJson({
        'id': 'visible',
        'financials_visible': true,
        'expected_cash': 9999,
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ShiftFinancialSummaryTab(shift: masked),
                ShiftKpiCards(shifts: [visible, masked]),
              ],
            ),
          ),
        ),
      );
      expect(find.text('shift_financials_withheld'), findsNWidgets(2));
      expect(find.textContaining('9999'), findsNothing);
      expect(find.textContaining('0.00'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'masked shift does not reconstruct withheld finance from counted cash',
    () {
      final shift = ShiftModel.fromJson({
        'id': 'synthetic',
        'financials_visible': false,
        'starting_cash': null,
        'expected_cash': null,
        'difference': null,
        'total_cash_sales': null,
        'actual_cash_counted': 130,
      });
      expect(shift.financialsVisible, isFalse);
      expect(shift.expectedCash, isNull);
      expect(shift.discrepancy, isNull);
      expect(shift.cashRevenue, isNull);
      expect(shift.expensesTotal, isNull);
      expect(shift.actualCash, 130);
      expect(ShiftModel.fromJson(shift.toJson()).financialsVisible, isFalse);
    },
  );
  for (final expected in [0, -20, 140]) {
    test('authoritative expected cash $expected is retained', () {
      final shift = ShiftModel.fromJson({
        'id': 'synthetic',
        'financials_visible': true,
        'starting_cash': 100,
        'expected_cash': expected,
        'actual_cash_counted': 130,
      });
      expect(shift.calculatedExpectedCash, expected);
      expect(shift.calculatedDiscrepancy, 130 - expected);
    });
  }
  test(
    'masked overview does not replace expected drawer with counted amount',
    () {
      final overview = LiveShiftOverviewModel.fromJson({
        'has_active_shift': true,
        'financials_visible': false,
        'expected_cash': null,
        'actual_cash_counted': 130,
      });
      expect(overview.hasActiveShift, isTrue);
      expect(overview.cashInDrawer, isNull);
    },
  );
}
