import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../art_core/theme/app_colors.dart';
import '../../../../art_core/theme/operations_tokens.dart';
import '../../../../art_core/widgets/app_text.dart';
import '../cubit/onboarding_state.dart';

class OnboardingReviewSummary extends StatelessWidget {
  final OnboardingState state;
  final String ownerName;
  final String ownerEmail;
  final bool hasMainImage;
  final bool hasIdentity;
  final bool hasBusinessDocument;
  final bool confirmed;
  final ValueChanged<bool> onConfirmed;

  const OnboardingReviewSummary({
    super.key,
    required this.state,
    required this.ownerName,
    required this.ownerEmail,
    required this.hasMainImage,
    required this.hasIdentity,
    required this.hasBusinessDocument,
    required this.confirmed,
    required this.onConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    final draft = state.draft;
    final arabic = context.locale.languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.heading(
          'onboarding_review.title'.tr(),
          fontSize: OperationsTokens.title.fontSize,
        ),
        const SizedBox(height: OperationsTokens.padding),
        AppText.body(
          'onboarding_review.notice'.tr(),
          fontSize: OperationsTokens.label.fontSize,
        ),
        const SizedBox(height: OperationsTokens.padding),
        AppText.body(
          'onboarding_review.owner'.tr(args: [ownerName, ownerEmail]),
          fontSize: OperationsTokens.label.fontSize,
        ),
        AppText.body(
          'onboarding_review.lounge'.tr(args: [draft.name]),
          fontSize: OperationsTokens.label.fontSize,
        ),
        AppText.body(
          draft.description,
          fontSize: OperationsTokens.label.fontSize,
        ),
        AppText.body(
          'onboarding_review.contact'.tr(args: [draft.contactPhone]),
          fontSize: OperationsTokens.label.fontSize,
        ),
        AppText.body(
          'onboarding_review.address'.tr(args: [draft.city, draft.address]),
          fontSize: OperationsTokens.label.fontSize,
        ),
        AppText.body(
          'onboarding_review.hours'.tr(args: [draft.opensAt, draft.closesAt]),
          fontSize: OperationsTokens.label.fontSize,
        ),
        const Divider(color: AppColors.borderDefault),
        AppText.subHeading(
          'onboarding_review.rooms'.tr(),
          fontSize: OperationsTokens.value.fontSize,
        ),
        for (final room in state.rooms)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: OperationsTokens.gap / 2,
            ),
            child: AppText.body(
              'onboarding_review.room'.tr(
                args: [
                  arabic ? room.nameAr : room.nameEn,
                  room.maxCapacity.toString(),
                  room.hourlyRateSingle.toStringAsFixed(2),
                  room.hourlyRateMulti.toStringAsFixed(2),
                ],
              ),
              fontSize: OperationsTokens.label.fontSize,
            ),
          ),
        const Divider(color: AppColors.borderDefault),
        AppText.body(
          'onboarding_review.products'.tr(
            args: [state.extras.length.toString()],
          ),
          fontSize: OperationsTokens.label.fontSize,
        ),
        AppText.body(
          'onboarding_review.attachments'.tr(
            args: [
              (hasMainImage
                      ? 'onboarding_review.selected'
                      : 'onboarding_review.missing')
                  .tr(),
              (hasIdentity
                      ? 'onboarding_review.selected'
                      : 'onboarding_review.missing')
                  .tr(),
              (hasBusinessDocument
                      ? 'onboarding_review.selected'
                      : 'onboarding_review.optional')
                  .tr(),
            ],
          ),
          fontSize: OperationsTokens.label.fontSize,
        ),
        const SizedBox(height: OperationsTokens.padding),
        CheckboxListTile(
          key: const ValueKey('onboarding-review-consent'),
          contentPadding: EdgeInsets.zero,
          value: confirmed,
          title: AppText.body(
            'onboarding_review.consent'.tr(),
            fontSize: OperationsTokens.label.fontSize,
          ),
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (value) => onConfirmed(value == true),
        ),
      ],
    );
  }
}
