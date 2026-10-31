import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/offline_cashier/presentation/offline_cash_amount.dart';

void main() {
  test('Arabic and Persian digits preserve exact cents', () {
    expect(parseOfflineCashMinor(' ٣٠٫٢٥ '), 3025);
    expect(parseOfflineCashMinor('۳۰.۵'), 3050);
    expect(parseOfflineCashMinor('0.01'), 1);
    expect(parseOfflineCashMinor('30'), 3000);
  });
  test('rejects ambiguous or invalid financial input instead of rounding', () {
    for (final input in [
      '',
      '0',
      '-1',
      '1.001',
      '1,000',
      '1e3',
      'NaN',
      '١٬٠٠٠',
      '1000000000000',
    ]) {
      expect(parseOfflineCashMinor(input), isNull, reason: input);
    }
  });
}
