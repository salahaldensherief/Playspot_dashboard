import 'package:equatable/equatable.dart';

class LoungePaymentSettings extends Equatable {
  final String loungeId;
  final bool allowCashPayment;
  final bool requirePrepaidFirstTime;
  final int cashGracePeriodMinutes;
  final String? walletNumber;
  final String? instapayHandle;
  final bool allowOpenTimeSessions;
  final int openTimeRoundingMinutes;
  final int openTimeMinMinutes;
  final int? openTimeMaxMinutes;

  const LoungePaymentSettings({
    required this.loungeId,
    this.allowCashPayment = true,
    this.requirePrepaidFirstTime = false,
    this.cashGracePeriodMinutes = 10,
    this.walletNumber,
    this.instapayHandle,
    this.allowOpenTimeSessions = false,
    this.openTimeRoundingMinutes = 15,
    this.openTimeMinMinutes = 60,
    this.openTimeMaxMinutes = 720,
  });

  @override
  List<Object?> get props => [
        loungeId,
        allowCashPayment,
        requirePrepaidFirstTime,
        cashGracePeriodMinutes,
        walletNumber,
        instapayHandle,
        allowOpenTimeSessions,
        openTimeRoundingMinutes,
        openTimeMinMinutes,
        openTimeMaxMinutes,
      ];

  LoungePaymentSettings copyWith({
    String? loungeId,
    bool? allowCashPayment,
    bool? requirePrepaidFirstTime,
    int? cashGracePeriodMinutes,
    String? walletNumber,
    String? instapayHandle,
    bool? allowOpenTimeSessions,
    int? openTimeRoundingMinutes,
    int? openTimeMinMinutes,
    int? openTimeMaxMinutes,
  }) {
    return LoungePaymentSettings(
      loungeId: loungeId ?? this.loungeId,
      allowCashPayment: allowCashPayment ?? this.allowCashPayment,
      requirePrepaidFirstTime: requirePrepaidFirstTime ?? this.requirePrepaidFirstTime,
      cashGracePeriodMinutes: cashGracePeriodMinutes ?? this.cashGracePeriodMinutes,
      walletNumber: walletNumber ?? this.walletNumber,
      instapayHandle: instapayHandle ?? this.instapayHandle,
      allowOpenTimeSessions: allowOpenTimeSessions ?? this.allowOpenTimeSessions,
      openTimeRoundingMinutes: openTimeRoundingMinutes ?? this.openTimeRoundingMinutes,
      openTimeMinMinutes: openTimeMinMinutes ?? this.openTimeMinMinutes,
      openTimeMaxMinutes: openTimeMaxMinutes ?? this.openTimeMaxMinutes,
    );
  }
}
