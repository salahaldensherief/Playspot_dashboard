import 'dart:convert';
import 'bridge_questionnaire_data.dart';

class BridgeQuestion {
  final Map<String, dynamic> rule;
  BridgeQuestion(this.rule);
  String get id => rule['id'] as String;
  List<String> get options => (rule['options'] as List).cast<String>();

  bool visible(Map<String, dynamic> answers) {
    final defaults = rule['defaults'] as Map;
    bool matches(Map condition) => condition.entries.every(
      (entry) => (entry.value as List).contains(
        answers[entry.key] ?? defaults[entry.key],
      ),
    );
    final any = rule['any'] as List;
    return matches(rule['when'] as Map) &&
        (any.isEmpty || any.any((c) => matches(c as Map)));
  }
}

class BridgeQuestionnaire {
  static final questions = (jsonDecode(bridgeQuestionnaireJson) as List)
      .map((q) => BridgeQuestion(Map<String, dynamic>.from(q as Map)))
      .toList(growable: false);

  /// Discard invalid and hidden cached answers before deriving advice.
  static Map<String, dynamic> normalize(Map<String, dynamic> answers) {
    final result = <String, dynamic>{};
    for (final q in questions) {
      final value = answers[q.id];
      if (value is! String) continue;
      if (q.options.isEmpty) {
        result[q.id] = value.trim().substring(
          0,
          value.trim().length.clamp(0, 120),
        );
      } else if (q.options.contains(value)) {
        result[q.id] = value;
      }
    }
    // Removing a parent may hide descendants in a subsequent pass.
    bool removed;
    do {
      removed = false;
      for (final q in questions) {
        if (!q.visible(result) && result.containsKey(q.id)) {
          result.remove(q.id);
          removed = true;
        }
      }
    } while (removed);
    return result;
  }
}
