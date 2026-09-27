import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import '../../domain/entities/lounge_payment_settings.dart';
import '../../domain/repositories/lounge_payment_settings_repository.dart';
import '../models/lounge_payment_settings_model.dart';

class LoungePaymentSettingsRepositoryImpl implements LoungePaymentSettingsRepository {
  final SupabaseClient client;

  LoungePaymentSettingsRepositoryImpl(this.client);

  @override
  Future<Either<Failure, LoungePaymentSettings>> getPaymentSettings(String loungeId) async {
    try {
      final response = await client
          .from('lounges')
          .select('id, allow_cash_payment, require_prepaid_first_time, cash_grace_period_minutes, wallet_number, instapay_handle, vodafone_cash_number, instapay_account')
          .eq('id', loungeId)
          .maybeSingle();

      if (response == null) {
        return Right(LoungePaymentSettings(loungeId: loungeId));
      }

      final model = LoungePaymentSettingsModel.fromJson(Map<String, dynamic>.from(response));
      return Right(model);
    } catch (e) {
      AppLogger.error('getPaymentSettings Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updatePaymentSettings(LoungePaymentSettings settings) async {
    try {
      final updateData = LoungePaymentSettingsModel(
        loungeId: settings.loungeId,
        allowCashPayment: settings.allowCashPayment,
        requirePrepaidFirstTime: settings.requirePrepaidFirstTime,
        cashGracePeriodMinutes: settings.cashGracePeriodMinutes,
        walletNumber: settings.walletNumber,
        instapayHandle: settings.instapayHandle,
      ).toJson();

      await client
          .from('lounges')
          .update(updateData)
          .eq('id', settings.loungeId);

      AppLogger.info('updatePaymentSettings Succeeded for loungeId: ${settings.loungeId}');
      return const Right(null);
    } on PostgrestException catch (e) {
      AppLogger.error('updatePaymentSettings PostgrestException: ${e.message} (code: ${e.code})');
      return Left(ServerFailure(e.message));
    } catch (e) {
      AppLogger.error('updatePaymentSettings Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }
}
