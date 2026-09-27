import 'dart:convert';

class BookingJsonParser {
  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static int parseInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  static List<Map<String, dynamic>> parseCanteenOrders(dynamic rawOrders) {
    if (rawOrders is String && rawOrders.trim().isNotEmpty) {
      try {
        rawOrders = jsonDecode(rawOrders);
      } catch (_) {}
    }
    if (rawOrders is List) {
      return rawOrders
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (rawOrders is Map) {
      return [Map<String, dynamic>.from(rawOrders)];
    }
    return <Map<String, dynamic>>[];
  }

  static List<Map<String, dynamic>> parseExtras(
    Map<String, dynamic> json,
    List<Map<String, dynamic>> parsedCanteenOrders,
  ) {
    final List<Map<String, dynamic>> itemsList = [];

    void addNormalizedItem(Map map) {
      final String? nameAr = map['name_ar']?.toString().trim();
      final String? nameEn = map['name_en']?.toString().trim();
      final String? nameDefault = map['name']?.toString().trim();
      final String? rawTitle = (map['title'] ??
              map['item_name'] ??
              map['extra_name'] ??
              map['product_name'])
          ?.toString()
          .trim();

      final resolvedName = (nameAr != null && nameAr.isNotEmpty && nameAr != 'null')
          ? nameAr
          : ((nameEn != null && nameEn.isNotEmpty && nameEn != 'null')
              ? nameEn
              : ((nameDefault != null &&
                      nameDefault.isNotEmpty &&
                      nameDefault != 'null' &&
                      nameDefault != 'canteen_order')
                  ? nameDefault
                  : ((rawTitle != null && rawTitle.isNotEmpty && rawTitle != 'null')
                      ? rawTitle
                      : 'صنف')));

      final qty = (map['quantity'] ?? map['qty'] ?? map['count'] as num?)?.toInt() ?? 1;
      final unitPrice = (map['unit_price'] ?? map['price'] ?? map['item_price'] as num?)
              ?.toDouble() ??
          0.0;
      final givenTotal =
          (map['total_price'] ?? map['total'] ?? map['amount'] as num?)?.toDouble();
      final totalPrice = givenTotal ?? (unitPrice * qty);

      itemsList.add({
        'id': (map['id'] ?? map['extra_id'] ?? map['product_id'])?.toString(),
        'extra_id': (map['extra_id'] ?? map['product_id'] ?? map['id'])?.toString(),
        'name': resolvedName,
        'name_ar': (nameAr != null && nameAr.isNotEmpty) ? nameAr : resolvedName,
        'name_en': (nameEn != null && nameEn.isNotEmpty) ? nameEn : resolvedName,
        'quantity': qty,
        'qty': qty,
        'unit_price': unitPrice,
        'price': unitPrice,
        'total_price': totalPrice,
        'status': map['status']?.toString(),
        'note': map['note']?.toString(),
      });
    }

    dynamic rawExtras = json['items'] ??
        json['booking_items'] ??
        json['extras'] ??
        json['canteen_items'] ??
        json['out_extras'];
    if (rawExtras is String && rawExtras.trim().isNotEmpty) {
      try {
        rawExtras = jsonDecode(rawExtras);
      } catch (_) {}
    }
    if (rawExtras is List) {
      for (final e in rawExtras) {
        if (e is Map) {
          addNormalizedItem(e);
        }
      }
    } else if (rawExtras is Map) {
      addNormalizedItem(rawExtras);
    }

    if (parsedCanteenOrders.isNotEmpty) {
      for (final order in parsedCanteenOrders) {
        final List<dynamic> sourceLists = [
          order['items'],
          order['canteen_order_items'],
          order['canteen_items'],
        ];

        for (final rawItems in sourceLists) {
          dynamic items = rawItems;
          if (items is String && items.trim().isNotEmpty) {
            try {
              items = jsonDecode(items);
            } catch (_) {}
          }
          if (items is List) {
            for (final it in items) {
              if (it is Map) {
                addNormalizedItem(it);
              }
            }
          }
        }
      }
    }

    return itemsList;
  }

  static double? parseCoordinate(
    Map<String, dynamic> json,
    Map<String, dynamic>? loungeData,
    bool isLat,
  ) {
    final key = isLat ? 'latitude' : 'longitude';
    final shortKey = isLat ? 'lat' : 'lng';
    final coordIndex = isLat ? 1 : 0;

    final val = json[key] ?? json[shortKey] ?? loungeData?[key] ?? loungeData?[shortKey];
    if (val != null) return parseDouble(val);

    final locPoint = json['location_point'] ?? loungeData?['location_point'];
    if (locPoint is Map &&
        locPoint['coordinates'] is List &&
        (locPoint['coordinates'] as List).length >= 2) {
      return parseDouble((locPoint['coordinates'] as List)[coordIndex]);
    }
    if (locPoint is String) {
      final match = RegExp(r'POINT\s*\(\s*([-\d.]+)\s+([-\d.]+)\s*\)', caseSensitive: false)
          .firstMatch(locPoint);
      if (match != null) {
        final groupIdx = isLat ? 2 : 1;
        return double.tryParse(match.group(groupIdx) ?? '');
      }
    }
    return null;
  }

  static String? parseReceiptUrl(Map<String, dynamic> json) {
    dynamic val = json['receipt_url'] ??
        json['out_receipt_url'] ??
        json['receipt_path'] ??
        json['out_receipt_path'] ??
        json['receipt'] ??
        json['payment_receipt'] ??
        json['payment_receipt_url'] ??
        json['payment_proof'] ??
        json['proof_url'] ??
        json['proof_image'] ??
        json['proof_path'] ??
        json['attachment_url'] ??
        json['attachment_path'] ??
        json['receipt_image'] ??
        json['receipt_image_url'] ??
        json['wallet_receipt'] ??
        json['transfer_receipt'];

    if (val == null && json['metadata'] is Map) {
      val = json['metadata']['receipt_url'] ??
          json['metadata']['receipt_path'] ??
          json['metadata']['receipt'] ??
          json['metadata']['payment_receipt'] ??
          json['metadata']['proof_url'];
    }

    if (val == null && json['bookings'] is Map) {
      val = json['bookings']['receipt_url'] ??
          json['bookings']['receipt_path'] ??
          json['bookings']['receipt'] ??
          json['bookings']['payment_receipt'];
    }

    if (val != null) {
      final str = val.toString().trim();
      if (str.isNotEmpty && str != 'null') return str;
    }
    return null;
  }
}
