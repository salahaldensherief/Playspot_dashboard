import 'package:easy_localization/easy_localization.dart';

String ownerProvisioningMessage(String? code) => switch (code) {
  'owner_session_expired' ||
  'owner_permission_denied' ||
  'owner_invalid_details' ||
  'owner_email_exists' ||
  'owner_provisioning_unconfirmed' => code!.tr(),
  _ => 'owner_account_create_failed'.tr(),
};
