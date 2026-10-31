import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/pricing_quote_entity.dart';
import '../entities/pricing_rule_entity.dart';

abstract class PricingRepository {
  Future<Either<Failure, List<PricingRuleEntity>>> getPricingRules({
    required String loungeId,
  });

  Future<Either<Failure, PricingRuleEntity>> savePricingRule(
    PricingRuleEntity rule,
  );

  Future<Either<Failure, void>> deletePricingRule(String id);

  Future<Either<Failure, List<PricingRuleEntity>>> checkRuleConflicts(
    PricingRuleEntity rule,
  );

  Future<Either<Failure, PricingQuoteEntity>> quoteBookingPrice({
    required String roomId,
    required String date,
    required String startTime,
    required String endTime,
    String playMode = 'single',
    int extraControllers = 0,
    String? couponCode,
  });

  Future<Either<Failure, List<Map<String, dynamic>>>> getRoomSlotsWithPrices({
    required String roomId,
    required String date,
  });

  Future<Either<Failure, Map<String, dynamic>>> getLoungePriceRange({
    required String loungeId,
  });
}
