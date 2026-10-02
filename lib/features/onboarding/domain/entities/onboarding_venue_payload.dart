import '../../../lounges/domain/entities/lounge.dart';
import 'lounge_draft_params.dart';

class OnboardingVenuePayload {
  static Map<String, dynamic> fromDraft({
    required Lounge lounge,
    required LoungeDraftParams draft,
    required String imageUrl,
    required List<String> galleryUrls,
  }) => {
    'name': lounge.name,
    'name_ar': lounge.name,
    'name_en': lounge.name,
    if (draft.brandName.isNotEmpty) 'brand_name': draft.brandName,
    if (draft.branchName.isNotEmpty) 'branch_name': draft.branchName,
    'contact_phone': draft.contactPhone,
    'vodafone_cash_number': draft.walletPhone.trim(),
    'instapay_account': draft.instapayAccount.trim(),
    'city': lounge.city ?? '',
    'location': lounge.location ?? '',
    'opening_time': lounge.opensAt,
    'closing_time': lounge.closesAt,
    'image_url': imageUrl,
    'images': galleryUrls,
    'description_ar': lounge.descriptionAr ?? lounge.descriptionEn ?? '',
    'description_en': lounge.descriptionEn ?? lounge.descriptionAr ?? '',
    'address': lounge.location ?? '',
    if (lounge.lat != null) 'lat': lounge.lat,
    if (lounge.lng != null) 'lng': lounge.lng,
  };
}
