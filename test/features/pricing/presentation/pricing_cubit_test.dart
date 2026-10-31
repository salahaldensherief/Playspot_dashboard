import 'dart:async';
import 'package:play_spot_dashboard/features/pricing/domain/entities/pricing_quote_entity.dart';
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

  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
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

  test(
    'loadPricingRules emits [loading, success] when usecase succeeds',
    () async {
      const loungeId = 'lounge-1';
      final params = GetPricingRulesParams(loungeId: loungeId);

      when(() => mockGetRules(params)).thenAnswer((_) async => Right([tRule]));

      final expectedStates = [
        const PricingState(status: PricingStatus.loading),
        PricingState(status: PricingStatus.success, rules: [tRule]),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadPricingRules(loungeId: loungeId);
    },
  );

  test(
    'loadPricingRules emits [loading, failure] when usecase fails',
    () async {
      const loungeId = 'lounge-1';
      final params = GetPricingRulesParams(loungeId: loungeId);

      when(() => mockGetRules(params)).thenAnswer(
        (_) async => const Left(ServerFailure('Error loading rules')),
      );

      final expectedStates = [
        const PricingState(status: PricingStatus.loading),
        const PricingState(
          status: PricingStatus.failure,
          errorMessage: 'Error loading rules',
        ),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadPricingRules(loungeId: loungeId);
    },
  );
  const quoteParams = QuoteBookingPriceParams(
    roomId: 'room',
    date: '2026-10-12',
    startTime: '12:00',
    endTime: '13:00',
  );
  const quote = PricingQuoteEntity(
    segments: [],
    roomSubtotal: 100,
    extraControllersAmount: 0,
    discountAmount: 0,
    total: 100,
  );
  Future<void> fetchQuote() => cubit.fetchLiveQuote(
    roomId: quoteParams.roomId,
    date: quoteParams.date,
    startTime: quoteParams.startTime,
    endTime: quoteParams.endTime,
  );

  test('late rule-load success cannot emit after close', () async {
    final pending = Completer<Either<Failure, List<PricingRuleEntity>>>();
    when(
      () => mockGetRules(const GetPricingRulesParams(loungeId: 'lounge-1')),
    ).thenAnswer((_) => pending.future);
    final request = cubit.loadPricingRules(loungeId: 'lounge-1');
    await cubit.close();
    pending.complete(Right([tRule]));
    await request;
  });
  test('conflict response after close never starts saving', () async {
    final pending = Completer<Either<Failure, List<PricingRuleEntity>>>();
    when(
      () => mockCheckConflicts(CheckPricingRuleConflictsParams(rule: tRule)),
    ).thenAnswer((_) => pending.future);
    final request = cubit.saveRule(tRule, loungeId: 'lounge-1');
    await cubit.close();
    pending.complete(const Right([]));
    expect(await request, false);
    verifyNever(() => mockSaveRule(SavePricingRuleParams(rule: tRule)));
  });
  test('save response after close never reloads the page', () async {
    final pending = Completer<Either<Failure, PricingRuleEntity>>();
    final started = Completer<void>();
    when(
      () => mockCheckConflicts(CheckPricingRuleConflictsParams(rule: tRule)),
    ).thenAnswer((_) async => const Right([]));
    when(() => mockSaveRule(SavePricingRuleParams(rule: tRule))).thenAnswer((
      _,
    ) {
      started.complete();
      return pending.future;
    });
    final request = cubit.saveRule(tRule, loungeId: 'lounge-1');
    await started.future;
    await cubit.close();
    pending.complete(Right(tRule));
    expect(await request, false);
    verifyNever(
      () => mockGetRules(const GetPricingRulesParams(loungeId: 'lounge-1')),
    );
  });
  test('delete failure arriving after close is ignored', () async {
    final pending = Completer<Either<Failure, void>>();
    when(
      () => mockDeleteRule(const DeletePricingRuleParams(id: 'rule-1')),
    ).thenAnswer((_) => pending.future);
    final request = cubit.deleteRule('rule-1', loungeId: 'lounge-1');
    await cubit.close();
    pending.complete(const Left(ServerFailure('Fixture failure')));
    await request;
  });
  test('quote response after close is ignored', () async {
    final pending = Completer<Either<Failure, PricingQuoteEntity>>();
    when(() => mockQuotePrice(quoteParams)).thenAnswer((_) => pending.future);
    final request = fetchQuote();
    await cubit.close();
    pending.complete(const Right(quote));
    await request;
  });
  test(
    'newer branch load supersedes a slow response from the previous branch',
    () async {
      final old = Completer<Either<Failure, List<PricingRuleEntity>>>();
      when(
        () => mockGetRules(const GetPricingRulesParams(loungeId: 'a')),
      ).thenAnswer((_) => old.future);
      when(
        () => mockGetRules(const GetPricingRulesParams(loungeId: 'b')),
      ).thenAnswer((_) async => const Right([]));
      final first = cubit.loadPricingRules(loungeId: 'a');
      await cubit.loadPricingRules(loungeId: 'b');
      old.complete(Right([tRule]));
      await first;
      expect(cubit.state.rules, isEmpty);
    },
  );
  test('failed live quote clears a previous successful preview', () async {
    when(
      () => mockQuotePrice(quoteParams),
    ).thenAnswer((_) async => const Right(quote));
    await fetchQuote();
    expect(cubit.state.liveQuote, quote);
    when(
      () => mockQuotePrice(quoteParams),
    ).thenAnswer((_) async => const Left(ServerFailure('Fixture outage')));
    await fetchQuote();
    expect(cubit.state.liveQuote, isNull);
  });
}
