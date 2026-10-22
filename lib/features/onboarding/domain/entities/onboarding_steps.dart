/// One flow definition shared by navigation, rendering and draft migration.
class OnboardingSteps {
  static const bridgePreviewEnabled = bool.fromEnvironment(
    'PLAYSPOT_BRIDGE_PREVIEW',
    defaultValue: false,
  );

  static List<String> ids({bool bridgeEnabled = bridgePreviewEnabled}) => [
    'venue',
    'basic',
    'location',
    'hours',
    'assets',
    'marketplace',
    'payment',
    'kyc',
    if (bridgeEnabled) 'bridge',
    'review',
  ];

  static int restore(
    Map<String, dynamic> json, {
    bool bridgeEnabled = bridgePreviewEnabled,
  }) {
    final steps = ids(bridgeEnabled: bridgeEnabled);
    final id = json['stepId'];
    if (id is String) {
      if (id == 'bridge' && !bridgeEnabled) return steps.indexOf('review');
      final index = steps.indexOf(id);
      if (index >= 0) return index;
    }
    final raw = json['step'];
    final index = raw is int ? raw : 0;
    // Before semantic IDs, only Bridge-preview drafts wrote this field.
    if (index >= 8) {
      if (index == 8 &&
          json.containsKey('integrationAnswers') &&
          bridgeEnabled) {
        return steps.indexOf('bridge');
      }
      return steps.indexOf('review');
    }
    return index.clamp(0, steps.length - 1);
  }
}
