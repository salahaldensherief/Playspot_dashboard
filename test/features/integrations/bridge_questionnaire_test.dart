import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/integrations/domain/services/bridge_questionnaire.dart';
import 'package:play_spot_dashboard/features/integrations/domain/services/bridge_questionnaire_data.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/entities/onboarding_steps.dart';

void main() {
  test('generated rules and bilingual catalog remain identical', () {
    final catalog =
        jsonDecode(File('docs/bridge/questionnaire.v1.json').readAsStringSync())
            as Map;
    expect(bridgeQuestionnaireVersion, catalog['version']);
    final expected = (catalog['questions'] as List)
        .map(
          (q) => {
            'id': q['id'],
            'options':
                (q['options'] as List?)?.map((o) => o['value']).toList() ?? [],
            'when': q['visibleWhen'] ?? {},
            'any': q['visibleWhenAny'] ?? [],
            'defaults': q['visibleWhenDefaults'] ?? {},
          },
        )
        .toList();
    expect(jsonDecode(bridgeQuestionnaireJson), expected);
    for (final locale in ['ar', 'en']) {
      final translations =
          jsonDecode(
                File('assets/translations/$locale.json').readAsStringSync(),
              )
              as Map;
      final bridge = translations['bridge_step'] as Map;
      for (final q in catalog['questions'] as List) {
        expect((bridge['questions'] as Map)[q['id']], q[locale]);
        for (final option in (q['options'] as List?) ?? []) {
          expect((bridge['options'] as Map)[option['value']], option[locale]);
        }
      }
      for (final q in BridgeQuestionnaire.questions) {
        expect((bridge['questions'] as Map)[q.id], isA<String>());
        for (final option in q.options) {
          expect((bridge['options'] as Map)[option], isA<String>());
        }
      }
    }
  });

  test('local API on a cloud system can collect the Windows host evidence', () {
    final answers = {
      'system': 'cloud',
      'supportsApi': 'yes',
      'apiReachability': 'localNetwork',
    };
    expect(
      BridgeQuestionnaire.questions
          .singleWhere((q) => q.id == 'hasWindowsComputer')
          .visible(answers),
      isTrue,
    );
  });

  test('hidden and invalid restored values cannot influence advice', () {
    expect(
      BridgeQuestionnaire.normalize({
        'system': 'none',
        'supportsApi': 'yes',
        'vendorName': 'stale',
        'sessionCommandsAvailable': 'yes',
        'password': 'discard',
      }),
      {'system': 'none'},
    );
    final answers = BridgeQuestionnaire.normalize({
      'system': 'cloud',
      'supportsApi': 'no',
      'apiReachability': 'publicHttps',
      'apiSessionCommandsAvailable': 'yes',
      'hasWindowsComputer': 'yes',
      'outboundInternetAvailable': 'yes',
      'availabilityReadable': 'unknown',
    });
    expect(answers, {
      'system': 'cloud',
      'supportsApi': 'no',
      'availabilityReadable': 'unknown',
    });
  });

  test(
    'flow defaults off; legacy review and preview drafts restore semantically',
    () {
      expect(
        OnboardingSteps.bridgePreviewEnabled,
        const bool.fromEnvironment('PLAYSPOT_BRIDGE_PREVIEW'),
      );
      expect(OnboardingSteps.ids(bridgeEnabled: false).length, 9);
      expect(OnboardingSteps.ids(bridgeEnabled: true).length, 10);
      expect(OnboardingSteps.restore({'step': 8}, bridgeEnabled: true), 9);
      expect(
        OnboardingSteps.restore({
          'step': 8,
          'integrationAnswers': {},
        }, bridgeEnabled: true),
        8,
      );
      expect(
        OnboardingSteps.restore({
          'step': 9,
          'integrationAnswers': {},
        }, bridgeEnabled: false),
        8,
      );
      expect(
        OnboardingSteps.restore({'stepId': 'review'}, bridgeEnabled: true),
        9,
      );
      expect(
        OnboardingSteps.restore({'stepId': 'bridge'}, bridgeEnabled: false),
        8,
      );
      expect(OnboardingSteps.restore({'step': -5}), 0);
      expect(OnboardingSteps.restore({'step': 'corrupt'}), 0);
    },
  );
}
