import 'package:easy_localization/easy_localization.dart';

String marketingMessage(String? code) => switch (code) {
  'promotion_not_found' ||
  'promotion_permission_denied' ||
  'promotion_session_expired' ||
  'promotion_invalid_details' => code!.tr(),
  _ => 'promotion_operation_failed'.tr(),
};
