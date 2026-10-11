import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/pricing/domain/entities/pricing_rule_entity.dart';
import 'package:play_spot_dashboard/features/pricing/domain/usecases/check_pricing_rule_conflicts_usecase.dart';
import 'package:play_spot_dashboard/features/pricing/domain/usecases/delete_pricing_rule_usecase.dart';
import 'package:play_spot_dashboard/features/pricing/domain/usecases/get_pricing_rules_usecase.dart';
import 'package:play_spot_dashboard/features/pricing/domain/usecases/quote_booking_price_usecase.dart';
import 'package:play_spot_dashboard/features/pricing/domain/usecases/save_pricing_rule_usecase.dart';
import 'package:play_spot_dashboard/features/pricing/presentation/pricing_cubit.dart';
import 'package:play_spot_dashboard/features/pricing/presentation/pricing_state.dart';

class MockGetPricingRulesUseCase extends Mock
    implements GetPricingRulesUseCase {}

class MockSavePricingRuleUseCase extends Mock
    implements SavePricingRuleUseCase {}

class MockDeletePricingRuleUseCase extends Mock
    implements DeletePricingRuleUseCase {}

class MockCheckPricingRuleConflictsUseCase extends Mock
    implements CheckPricingRuleConflictsUseCase {}

class MockQuoteBookingPriceUseCase extends Mock
    implements QuoteBookingPriceUseCase {}

void main() {
  late PricingCubit cubit;
  late MockGetPricingRulesUseCase mockGetRules;
  late MockSavePricingRuleUseCase mockSaveRule;
  late MockDeletePricingRuleUseCase mockDeleteRule;
  late MockCheckPricingRuleConflictsUseCase mockCheckConflicts;
  late MockQuoteBookingPriceUseCase mockQuotePrice;

  setUp(() {
    mockGetRules = MockGetPricingRulesUseCase();
    mockSaveRule = MockSavePricingRuleUseCase();
    mockDeleteRule = MockDeletePricingRuleUseCase();
    mockCheckConflicts = MockCheckPricingRuleConflictsUseCase();
    mockQuotePrice = MockQuoteBookingPriceUseCase();

    cubit = PricingCubit(
      getPricingRulesUseCase: mockGetRules,
      savePricingRuleUseCase: mockSaveRule,
      deletePricingRuleUseCase: mockDeleteRule,
      checkPricingRuleConflictsUseCase: mockCheckConflicts,
      quoteBookingPriceUseCase: mockQuotePrice,
    );
  });

  tearDown(() {
    cubit.close();
  });

  final tRule = PricingRuleEntity(
    id: 'rule-1',
    loungeId: 'lounge-1',
    nameAr: 'ذروة مساءً',
    nameEn: 'Evening Peak',
    startTime: '16:00:00',
    endTime: '22:00:00',
    createdAt: DateTime(2026, 3, 30),
  );

  test('initial state should be PricingState()', () {
    expect(cubit.state, const PricingState());
  });

  test('loadPricingRules emits [loading, success] when usecase succeeds', () async {
    const loungeId = 'lounge-1';
    final params = GetPricingRulesParams(loungeId: loungeId);

    when(() => mockGetRules(params)).thenAnswer((_) async => Right([tRule]));

    final expectedStates = [
      const PricingState(status: PricingStatus.loading),
      PricingState(status: PricingStatus.success, rules: [tRule]),
    ];

    expectLater(cubit.stream, emitsInOrder(expectedStates));

    await cubit.loadPricingRules(loungeId: loungeId);
  });

  test('loadPricingRules emits [loading, failure] when usecase fails', () async {
    const loungeId = 'lounge-1';
    final params = GetPricingRulesParams(loungeId: loungeId);

    when(() => mockGetRules(params))
        .thenAnswer((_) async => const Left(ServerFailure('Error loading rules')));

    final expectedStates = [
      const PricingState(status: PricingStatus.loading),
      const PricingState(
        status: PricingStatus.failure,
        errorMessage: 'Error loading rules',
      ),
    ];

    expectLater(cubit.stream, emitsInOrder(expectedStates));

    await cubit.loadPricingRules(loungeId: loungeId);
  });
}
