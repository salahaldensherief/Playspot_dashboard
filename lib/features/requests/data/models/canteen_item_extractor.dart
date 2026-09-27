import 'dart:convert';

class CanteenItemExtractor {
  static List<Map<String, dynamic>> extract(Map<String, dynamic> json) {
    List<Map<String, dynamic>> parsedItems = [];

    _extractItems(json['request_data'], parsedItems);
    _extractItems(json['canteen_order_items'], parsedItems);
    _extractItems(json['items'], parsedItems);
    _extractItems(json['canteen_items'], parsedItems);
    _extractItems(json['booking_items'], parsedItems);

    if (json['canteen_orders'] != null) {
      if (json['canteen_orders'] is List) {
        for (var order in (json['canteen_orders'] as List)) {
          if (order is Map) {
            _extractItems(order['items'], parsedItems);
            _extractItems(order['canteen_order_items'], parsedItems);
          }
        }
      } else if (json['canteen_orders'] is Map) {
        _extractItems((json['canteen_orders'] as Map)['items'], parsedItems);
      }
    }

    return parsedItems;
  }

  static void _extractItems(dynamic rawItems, List<Map<String, dynamic>> targetList) {
    if (rawItems == null) return;

    void processItem(Map<String, dynamic> itemMap) {
      final extraObj = itemMap['extras'] ?? itemMap['canteen_items'] ?? itemMap['extra'] ?? itemMap['item'];
      if (extraObj is Map) {
        final String? nestedNameAr = extraObj['name_ar']?.toString().trim();
        final String? nestedNameEn = extraObj['name_en']?.toString().trim();
        final String? nestedNameDefault = extraObj['name']?.toString().trim();
        final String? nestedTitle = extraObj['title']?.toString().trim();
        final String resolvedNested = (nestedNameAr != null && nestedNameAr.isNotEmpty)
            ? nestedNameAr
            : ((nestedNameEn != null && nestedNameEn.isNotEmpty)
                ? nestedNameEn
                : ((nestedNameDefault != null && nestedNameDefault.isNotEmpty)
                    ? nestedNameDefault
                    : (nestedTitle ?? '')));

        if (resolvedNested.isNotEmpty) {
          itemMap['name'] = resolvedNested;
          itemMap['name_ar'] = nestedNameAr ?? resolvedNested;
          itemMap['name_en'] = nestedNameEn ?? resolvedNested;
        }
        itemMap['price'] = extraObj['price'] ?? extraObj['unit_price'] ?? itemMap['price'] ?? itemMap['unit_price'];
      }

      final String? nameAr = itemMap['name_ar']?.toString().trim();
      final String? nameEn = itemMap['name_en']?.toString().trim();
      final String? nameDefault = itemMap['name']?.toString().trim();
      final String? rawTitle = (itemMap['extra_name'] ?? itemMap['item_name'] ?? itemMap['title'])?.toString().trim();

      final resolvedName = (nameAr != null && nameAr.isNotEmpty && nameAr != 'null')
          ? nameAr
          : ((nameEn != null && nameEn.isNotEmpty && nameEn != 'null')
              ? nameEn
              : ((nameDefault != null && nameDefault.isNotEmpty && nameDefault != 'null' && nameDefault != 'Extra Item')
                  ? nameDefault
                  : ((rawTitle != null && rawTitle.isNotEmpty && rawTitle != 'null') ? rawTitle : 'صنف')));

      itemMap['name'] = resolvedName;
      itemMap['name_ar'] = (nameAr != null && nameAr.isNotEmpty) ? nameAr : resolvedName;
      itemMap['name_en'] = (nameEn != null && nameEn.isNotEmpty) ? nameEn : resolvedName;

      itemMap['quantity'] = itemMap['quantity'] ?? itemMap['qty'] ?? itemMap['count'] ?? 1;
      itemMap['price'] = itemMap['price'] ?? itemMap['unit_price'] ?? itemMap['unitPrice'] ?? 0.0;
      itemMap['unit_price'] = itemMap['unit_price'] ?? itemMap['price'] ?? 0.0;
      itemMap['total_price'] = itemMap['total_price'] ??
          ((itemMap['quantity'] as num).toInt() * (itemMap['price'] as num).toDouble());
      itemMap['extra_id'] = (itemMap['extra_id'] ?? itemMap['product_id'] ?? itemMap['id'])?.toString();

      targetList.add(itemMap);
    }

    if (rawItems is String) {
      try {
        final decoded = jsonDecode(rawItems);
        if (decoded is List) {
          for (var i in decoded) {
            if (i is Map) {
              processItem(Map<String, dynamic>.from(i));
            }
          }
        } else if (decoded is Map) {
          processItem(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {}
    } else if (rawItems is List) {
      for (var i in rawItems) {
        if (i is Map) {
          processItem(Map<String, dynamic>.from(i));
        }
      }
    } else if (rawItems is Map) {
      processItem(Map<String, dynamic>.from(rawItems));
    }
  }
}
