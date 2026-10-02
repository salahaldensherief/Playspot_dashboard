import '../entities/lounge_draft_params.dart';

class OnboardingSubmissionValidator {
  static String? validate(
    LoungeDraftParams draft, {
    required int roomCount,
    required bool hasMainImage,
    required bool hasIdentityDocument,
  }) {
    if ([
      draft.name,
      draft.description,
      draft.city,
      draft.address,
    ].any((value) => value.trim().isEmpty)) {
      return 'onboarding_validation.details_required';
    }
    final phone = draft.contactPhone.replaceAll(RegExp(r'[\s()\-]'), '');
    if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(phone)) {
      return 'onboarding_validation.phone_required';
    }
    if (!_validTime(draft.opensAt) ||
        !_validTime(draft.closesAt) ||
        draft.opensAt.trim() == draft.closesAt.trim()) {
      return 'onboarding_validation.hours_required';
    }
    if (roomCount < 1) return 'onboarding_validation.rooms_required';
    if (draft.lat == null ||
        draft.lng == null ||
        !draft.lat!.isFinite ||
        !draft.lng!.isFinite ||
        draft.lat!.abs() > 90 ||
        draft.lng!.abs() > 180) {
      return 'onboarding_validation.coordinates_required';
    }
    if (draft.walletPhone.trim().isEmpty &&
        draft.instapayAccount.trim().isEmpty) {
      return 'onboarding_validation.payment_required';
    }
    if (draft.walletPhone.trim().isNotEmpty &&
        !RegExp(r'^\+?[0-9]{8,15}$').hasMatch(draft.walletPhone.trim())) {
      return 'onboarding_validation.wallet_invalid';
    }
    if (!hasMainImage) return 'onboarding_validation.image_required';
    if (!hasIdentityDocument) return 'onboarding_validation.identity_required';
    return null;
  }

  static bool _validTime(String value) =>
      RegExp(r'^(?:[01]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(value.trim());
}
