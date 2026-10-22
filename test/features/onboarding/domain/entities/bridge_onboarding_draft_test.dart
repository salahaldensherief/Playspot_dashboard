import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/entities/lounge_draft_params.dart';

void main() {
  test(
    'bridge readiness answers survive local onboarding draft round trip',
    () {
      const initial = LoungeDraftParams(
        step: 8,
        integrationAnswers: {
          'system': 'windowsLocal',
          'vendorName': 'Fixture POS',
          'supportsApi': 'no',
          'hasWindowsComputer': 'yes',
        },
      );
      final parsed = LoungeDraftParams.fromJson(initial.toJson());
      expect(parsed.step, 8);
      expect(parsed.integrationAnswers, initial.integrationAnswers);
      expect(
        parsed.copyWith(step: 9).integrationAnswers,
        initial.integrationAnswers,
      );
    },
  );

  test('old saved drafts restore without requiring a new bridge field', () {
    final parsed = LoungeDraftParams.fromJson({
      'step': 8,
      'name': 'Demo Lounge',
    });
    expect(parsed.integrationAnswers, isEmpty);
  });
}
