import '../../../lounges/data/models/lounge_model.dart';
import '../../../lounges/data/models/extra_model.dart';
import '../../../rooms/data/models/room_model.dart';
import '../../domain/entities/lounge_draft_params.dart';
import '../../domain/entities/saved_onboarding_draft.dart';

class SavedOnboardingDraftModel extends SavedOnboardingDraft {
  const SavedOnboardingDraftModel({
    super.reviewNotes,
    required super.lounge,
    required super.fields,
    required super.rooms,
    required super.extras,
  });

  factory SavedOnboardingDraftModel.fromJson(Map<String, dynamic> json) {
    if (json['lounge'] is! Map ||
        json['rooms'] is! List ||
        json['extras'] is! List) {
      throw const FormatException('invalid_saved_onboarding_draft');
    }
    final raw = Map<String, dynamic>.from(json['lounge'] as Map);
    final lounge = LoungeModel.fromJson(raw);
    return SavedOnboardingDraftModel(
      reviewNotes: json['review_notes']?.toString(),
      lounge: lounge,
      fields: LoungeDraftParams(
        name: lounge.name,
        description: lounge.descriptionAr ?? lounge.descriptionEn ?? '',
        city: lounge.city ?? '',
        address: raw['address']?.toString() ?? lounge.location ?? '',
        contactPhone: raw['contact_phone']?.toString() ?? '',
        opensAt: lounge.opensAt.length >= 5
            ? lounge.opensAt.substring(0, 5)
            : lounge.opensAt,
        closesAt: lounge.closesAt.length >= 5
            ? lounge.closesAt.substring(0, 5)
            : lounge.closesAt,
        lat: lounge.lat,
        lng: lounge.lng,
        walletPhone: lounge.vodafoneCashNumber ?? '',
        instapayAccount: lounge.instapayAccount ?? '',
        branchName: raw['branch_name']?.toString() ?? '',
      ),
      rooms: List.unmodifiable(
        (json['rooms'] as List).map(
          (r) => RoomModel.fromJson(Map<String, dynamic>.from(r as Map)),
        ),
      ),
      extras: List.unmodifiable(
        (json['extras'] as List).map(
          (e) => ExtraModel.fromJson(Map<String, dynamic>.from(e as Map)),
        ),
      ),
    );
  }
}
