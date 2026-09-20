import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../entities/lounge_payment_settings.dart';

abstract class LoungePaymentSettingsRepository {
  Future<Either<Failure, LoungePaymentSettings>> getPaymentSettings(String loungeId);
  Future<Either<Failure, void>> updatePaymentSettings(LoungePaymentSettings settings);
}
