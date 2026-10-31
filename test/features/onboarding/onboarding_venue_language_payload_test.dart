import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/entities/lounge_draft_params.dart';
import 'package:play_spot_dashboard/features/onboarding/domain/entities/onboarding_venue_payload.dart';

void main() {
  test('venue payload keeps Arabic and English values separate', () {
    const draft = LoungeDraftParams(
      name: 'صالة الألعاب',
      nameEn: 'Game Lounge',
      description: 'وصف عربي',
      descriptionEn: 'English description',
    );
    const lounge = Lounge(
      id: 'lounge-id',
      name: 'صالة الألعاب',
      imageUrl: '',
      opensAt: '10:00',
      closesAt: '22:00',
    );

    final payload = OnboardingVenuePayload.fromDraft(
      lounge: lounge,
      draft: draft,
      imageUrl: '',
      galleryUrls: const [],
    );

    expect(payload['name_ar'], 'صالة الألعاب');
    expect(payload['name_en'], 'Game Lounge');
    expect(payload['description_ar'], 'وصف عربي');
    expect(payload['description_en'], 'English description');
  });
}
