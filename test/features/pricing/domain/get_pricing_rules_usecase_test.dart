import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/pricing/domain/entities/pricing_rule_entity.dart';
import 'package:play_spot_dashboard/features/pricing/domain/repositories/pricing_repository.dart';
import 'package:play_spot_dashboard/features/pricing/domain/usecases/get_pricing_rules_usecase.dart';

class MockPricingRepository extends Mock implements PricingRepository {}

void main() {
  late GetPricingRulesUseCase usecase;
  late MockPricingRepository mockRepository;

  setUp(() {
    mockRepository = MockPricingRepository();
    usecase = GetPricingRulesUseCase(mockRepository);
  });

  const tParams = GetPricingRulesParams(loungeId: 'lounge-123');
  final tRule = PricingRuleEntity(
    id: 'rule-1',
    loungeId: 'lounge-123',
    nameAr: 'ذروة مساءً',
    nameEn: 'Evening Peak',
    startTime: '16:00:00',
    endTime: '22:00:00',
    createdAt: DateTime(2026, 3, 30),
  );

  test('should return list of PricingRuleEntity when repository call is successful', () async {
    when(() => mockRepository.getPricingRules(loungeId: tParams.loungeId))
        .thenAnswer((_) async => Right([tRule]));

    final result = await usecase(tParams);

    expect(result.isRight(), true);
    result.fold(
      (failure) => fail('Should have succeeded'),
      (rules) {
        expect(rules.length, 1);
        expect(rules.first.id, 'rule-1');
      },
    );
    verify(() => mockRepository.getPricingRules(loungeId: tParams.loungeId)).called(1);
  });

  test('should return ServerFailure when repository call fails', () async {
    const tFailure = ServerFailure('Database query error');
    when(() => mockRepository.getPricingRules(loungeId: tParams.loungeId))
        .thenAnswer((_) async => const Left(tFailure));

    final result = await usecase(tParams);

    expect(result, const Left(tFailure));
    verify(() => mockRepository.getPricingRules(loungeId: tParams.loungeId)).called(1);
  });
}
