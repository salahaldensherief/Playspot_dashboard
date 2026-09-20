import 'package:play_spot_dashboard/features/lounges/domain/entities/extra_entity.dart';

String resolveItemName(Map<String, dynamic> itemMap, List<ExtraEntity> availableExtras) {
  // 1. Direct name fields prioritizing Arabic / English / Default name
  final candidateName = itemMap['name_ar'] ??
      itemMap['name_en'] ??
      itemMap['name'] ??
      itemMap['extra_name'] ??
      itemMap['item_name'] ??
      itemMap['product_name'] ??
      itemMap['title'] ??
      itemMap['display_name'];

  if (candidateName != null &&
      candidateName.toString().trim().isNotEmpty &&
      candidateName.toString().trim() != 'Extra Item' &&
      candidateName.toString().trim() != 'canteen_order' &&
      candidateName.toString().trim() != 'طلب كافيتريا' &&
      candidateName.toString().trim() != 'null') {
    return candidateName.toString().trim();
  }

  // 2. Nested objects check (extras, extra, canteen_items, item, canteen_item)
  final nestedObj = itemMap['extras'] ??
      itemMap['extra'] ??
      itemMap['canteen_items'] ??
      itemMap['item'] ??
      itemMap['canteen_item'];

  if (nestedObj is Map) {
    final nestedName = nestedObj['name_ar'] ??
        nestedObj['name_en'] ??
        nestedObj['name'] ??
        nestedObj['title'];
    if (nestedName != null &&
        nestedName.toString().trim().isNotEmpty &&
        nestedName.toString().trim() != 'null') {
      return nestedName.toString().trim();
    }
  }

  // 3. Match extra_id / product_id / item_id / id against availableExtras
  final extraId = (itemMap['extra_id'] ??
      itemMap['product_id'] ??
      itemMap['item_id'] ??
      itemMap['canteen_item_id'] ??
      itemMap['id'])?.toString();

  if (extraId != null && extraId.isNotEmpty) {
    try {
      final matched = availableExtras.firstWhere(
        (e) => e.id == extraId || e.id.toLowerCase() == extraId.toLowerCase(),
      );
      final matchedName = matched.nameAr.isNotEmpty
          ? matched.nameAr
          : (matched.name.isNotEmpty ? matched.name : matched.nameEn);
      if (matchedName.isNotEmpty) return matchedName;
    } catch (_) {}
  }

  return 'صنف';
}
