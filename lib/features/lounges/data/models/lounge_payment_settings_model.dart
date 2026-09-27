import '../../domain/entities/lounge_payment_settings.dart';

class LoungePaymentSettingsModel extends LoungePaymentSettings {
  const LoungePaymentSettingsModel({
    required super.loungeId,
    super.allowCashPayment = true,
    super.requirePrepaidFirstTime = false,
    super.cashGracePeriodMinutes = 10,
    super.walletNumber,
    super.instapayHandle,
  });

  factory LoungePaymentSettingsModel.fromJson(Map<String, dynamic> json) {
    int parseGracePeriod(dynamic val) {
      if (val == null) return 10;
      final parsed = val is num ? val.toInt() : int.tryParse(val.toString());
      if (parsed == null) return 10;
      if (parsed < 0) return 0;
      if (parsed > 1440) return 1440;
      return parsed;
    }

    return LoungePaymentSettingsModel(
      loungeId: (json['id'] ?? json['lounge_id'] ?? '').toString(),
      allowCashPayment: json['allow_cash_payment'] ?? true,
      requirePrepaidFirstTime: json['require_prepaid_first_time'] ?? false,
      cashGracePeriodMinutes: parseGracePeriod(json['cash_grace_period_minutes']),
      walletNumber: (json['wallet_number'] ?? json['vodafone_cash_number'] ?? json['vodafone_cash'])?.toString(),
      instapayHandle: (json['instapay_handle'] ?? json['instapay_account'] ?? json['instapay'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'allow_cash_payment': allowCashPayment,
      'require_prepaid_first_time': requirePrepaidFirstTime,
      'cash_grace_period_minutes': cashGracePeriodMinutes,
      if (walletNumber != null) 'wallet_number': walletNumber,
      if (instapayHandle != null) 'instapay_handle': instapayHandle,
    };
  }
}
