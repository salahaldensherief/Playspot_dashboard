import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/entities/lounge_draft_params.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/services/onboarding_submission_validator.dart';

void main() {
  const draft = LoungeDraftParams(
    name: 'Lounge',
    description: 'Gaming lounge',
    city: 'Cairo',
    address: 'Street 1',
    contactPhone: '+201001234567',
    opensAt: '10:00',
    closesAt: '02:00',
  );
  String? validate(
    LoungeDraftParams value, {
    int rooms = 1,
    bool image = true,
    bool identity = true,
  }) => OnboardingSubmissionValidator.validate(
    value,
    roomCount: rooms,
    hasMainImage: image,
    hasIdentityDocument: identity,
  );
  test('allows complete lounge with overnight operating hours', () {
    expect(validate(draft), isNull);
  });
  test('rejects each missing core field', () {
    for (final incomplete in [
      draft.copyWith(name: ' '),
      draft.copyWith(description: ''),
      draft.copyWith(city: ''),
      draft.copyWith(address: ''),
    ]) {
      expect(validate(incomplete), 'onboarding_validation.details_required');
    }
  });
  test(
    'rejects invalid contact phone without accepting alphabetic numbers',
    () {
      expect(
        validate(draft.copyWith(contactPhone: 'phone123456789')),
        'onboarding_validation.phone_required',
      );
    },
  );
  test('rejects malformed or identical operating hours', () {
    for (final hours in ['24:00', '12:99', 'random', '02:00']) {
      expect(
        validate(draft.copyWith(opensAt: hours)),
        'onboarding_validation.hours_required',
      );
    }
  });
  test('requires room, lounge image and identity separately', () {
    expect(validate(draft, rooms: 0), 'onboarding_validation.rooms_required');
    expect(
      validate(draft, image: false),
      'onboarding_validation.image_required',
    );
    expect(
      validate(draft, identity: false),
      'onboarding_validation.identity_required',
    );
  });
  test('contact details survive draft serialization', () {
    expect(LoungeDraftParams.fromJson(draft.toJson()), draft);
    expect(LoungeDraftParams.fromJson({'name': 'legacy'}).contactPhone, '');
  });
}
