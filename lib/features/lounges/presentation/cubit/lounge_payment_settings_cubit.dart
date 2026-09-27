import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/lounge_payment_settings.dart';
import '../../domain/repositories/lounge_payment_settings_repository.dart';
import 'lounge_payment_settings_state.dart';

class LoungePaymentSettingsCubit extends Cubit<LoungePaymentSettingsState> {
  final LoungePaymentSettingsRepository repository;

  LoungePaymentSettingsCubit(this.repository)
      : super(const LoungePaymentSettingsState());

  Future<void> loadSettings(String loungeId) async {
    if (loungeId.isEmpty) return;

    emit(state.copyWith(
      status: LoungePaymentSettingsStatus.loading,
      clearError: true,
    ));

    final result = await repository.getPaymentSettings(loungeId);

    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: LoungePaymentSettingsStatus.failure,
        errorMessage: failure.message,
      )),
      (settings) => emit(state.copyWith(
        status: LoungePaymentSettingsStatus.loaded,
        settings: settings,
        clearError: true,
      )),
    );
  }

  Future<bool> saveSettings(LoungePaymentSettings newSettings) async {
    final previousSettings = state.settings;

    // Optimistic UI update with explicit rollback
    emit(state.copyWith(
      status: LoungePaymentSettingsStatus.saving,
      settings: newSettings,
      clearError: true,
    ));

    final result = await repository.updatePaymentSettings(newSettings);

    if (isClosed) return false;

    return result.fold(
      (failure) {
        // Rollback to previous settings on failure
        emit(state.copyWith(
          status: LoungePaymentSettingsStatus.failure,
          settings: previousSettings,
          errorMessage: failure.message,
        ));
        return false;
      },
      (_) {
        emit(state.copyWith(
          status: LoungePaymentSettingsStatus.success,
          settings: newSettings,
          clearError: true,
        ));
        return true;
      },
    );
  }
}
