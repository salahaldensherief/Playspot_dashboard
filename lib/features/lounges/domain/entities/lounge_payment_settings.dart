import 'package:equatable/equatable.dart';

class LoungePaymentSettings extends Equatable {
  final String loungeId;
  final bool allowCashPayment;
  final bool requirePrepaidFirstTime;
  final int cashGracePeriodMinutes;
  final String? walletNumber;
  final String? instapayHandle;

  const LoungePaymentSettings({
    required this.loungeId,
    this.allowCashPayment = true,
    this.requirePrepaidFirstTime = false,
    this.cashGracePeriodMinutes = 10,
    this.walletNumber,
    this.instapayHandle,
  });

  @override
  List<Object?> get props => [
        loungeId,
        allowCashPayment,
        requirePrepaidFirstTime,
        cashGracePeriodMinutes,
        walletNumber,
        instapayHandle,
      ];

  LoungePaymentSettings copyWith({
    String? loungeId,
    bool? allowCashPayment,
    bool? requirePrepaidFirstTime,
    int? cashGracePeriodMinutes,
    String? walletNumber,
    String? instapayHandle,
  }) {
    return LoungePaymentSettings(
      loungeId: loungeId ?? this.loungeId,
      allowCashPayment: allowCashPayment ?? this.allowCashPayment,
      requirePrepaidFirstTime: requirePrepaidFirstTime ?? this.requirePrepaidFirstTime,
      cashGracePeriodMinutes: cashGracePeriodMinutes ?? this.cashGracePeriodMinutes,
      walletNumber: walletNumber ?? this.walletNumber,
      instapayHandle: instapayHandle ?? this.instapayHandle,
    );
  }
}
