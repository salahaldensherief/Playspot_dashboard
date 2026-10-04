import 'package:easy_localization/easy_localization.dart';

// Historical reason values remain unchanged in RPC payloads and saved reports.
String moderationReasonLabel(String reason) {
  final key = switch (reason) {
    'سلوك غير لائق وتخريب' => 'moderation_reason_misconduct',
    'عدم الحضور وتخلف متكرر (No-Show)' => 'moderation_reason_no_show',
    'تزوير إيصال الدفع / احتيال' => 'moderation_reason_fraud',
    'إزعاج العملاء الآخرين والاعتداء اللفظي' => 'moderation_reason_harassment',
    'أخرى' => 'moderation_reason_other',
    _ => null,
  };
  return key == null ? reason : key.tr();
}
