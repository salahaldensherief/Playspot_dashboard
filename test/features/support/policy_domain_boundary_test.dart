import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/features/support/data/datasources/support_remote_data_source.dart';
import 'package:play_spot_dashboard/features/support/data/models/app_policy_model.dart';
import 'package:play_spot_dashboard/features/support/data/repositories/support_repository_impl.dart';
import 'package:play_spot_dashboard/features/support/domain/entities/app_policy_entity.dart';

class _Remote extends Mock implements SupportRemoteDataSource {}

void main() {
  const fallback = AppPolicyEntity(
    id: '',
    policyType: 'refund_policy',
    titleAr: 'استرداد',
    titleEn: 'Refund',
    contentAr: '',
    contentEn: '',
  );

  for (final models in [
    <AppPolicyModel>[],
    <AppPolicyModel>[
      AppPolicyModel(
        id: 'terms_of_service',
        policyType: 'terms_of_service',
        titleAr: 'شروط',
        titleEn: 'Terms',
        contentAr: 'المحتوى العربي',
        contentEn: 'English content',
        isPublished: false,
        updatedAt: DateTime.utc(2026, 10, 2),
      ),
    ],
  ]) {
    test(
      'policy domain fallback works for ${models.length} remote models',
      () async {
        final remote = _Remote();
        when(() => remote.getPolicies()).thenAnswer((_) async => models);
        final result = await SupportRepositoryImpl(remote).getPolicies();
        result.fold((failure) => fail(failure.message), (policies) {
          // A List<AppPolicyModel> masquerading as List<AppPolicyEntity> rejects
          // this domain callback at runtime, even before testing a predicate.
          expect(
            policies.firstWhere(
              (policy) => policy.policyType == 'refund_policy',
              orElse: () => fallback,
            ),
            same(fallback),
          );
          if (models.isNotEmpty) {
            final policy = policies.firstWhere(
              (policy) => policy.policyType == 'terms_of_service',
              orElse: () => fallback,
            );
          expect(policy.id, models.first.id);
          expect(policy.policyType, models.first.policyType);
          expect(policy.titleAr, models.first.titleAr);
          expect(policy.titleEn, models.first.titleEn);
            expect(policy.isPublished, isFalse);
            expect(policy.updatedAt, DateTime.utc(2026, 10, 2));
            expect(policy.contentAr, 'المحتوى العربي');
            expect(policy.contentEn, 'English content');
          }
        });
      },
    );
  }
}
