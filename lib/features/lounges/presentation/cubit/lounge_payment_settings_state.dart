import 'package:equatable/equatable.dart';
import '../../domain/entities/lounge_payment_settings.dart';

enum LoungePaymentSettingsStatus { initial, loading, loaded, saving, success, failure }

class LoungePaymentSettingsState extends Equatable {
  final LoungePaymentSettingsStatus status;
  final LoungePaymentSettings? settings;
  final String? errorMessage;

  const LoungePaymentSettingsState({
    this.status = LoungePaymentSettingsStatus.initial,
    this.settings,
    this.errorMessage,
  });

  LoungePaymentSettingsState copyWith({
    LoungePaymentSettingsStatus? status,
    LoungePaymentSettings? settings,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LoungePaymentSettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, settings, errorMessage];
}
