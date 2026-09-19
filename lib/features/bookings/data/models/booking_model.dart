import 'dart:convert';
import '../../domain/entities/booking.dart';

class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.userId,
    super.userName,
    super.userEmail,
    super.userPhone,
    required super.loungeId,
    required super.roomId,
    super.loungeName = '',
    super.loungeLocation = '',
    super.roomName = '',
    super.controllersCount = 0,
    super.screenSize = '',
    required super.date,
    required super.startTime,
    required super.endTime,
    super.durationMinutes = 60,
    required super.status,
    required super.paymentStatus,
    required super.totalPrice,
    super.addonsPrice,
    super.voucherDiscount,
    super.voucherCode,
    super.discountAmount,
    super.discountPercentage,
    super.discountReason,
    super.extras = const [],
    super.canteenOrders = const [],
    super.lat,
    super.lng,
    super.shiftId,
    super.playMode,
    super.roomPrice,
    super.visitNumber,
    super.paymentMethod,
    super.receiptUrl,
    super.expiresAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    int parseInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? defaultValue;
    }

    final profileData = json['profiles'] as Map<String, dynamic>?;
    final roomData = json['rooms'] as Map<String, dynamic>?;
    final loungeData = json['lounges'] as Map<String, dynamic>?;

    final String userName = (
      json['out_user_name'] ?? 
      json['user_name'] ?? 
      json['userName'] ?? 
      profileData?['full_name'] ?? 
      profileData?['name'] ?? 
      json['full_name'] ?? 
      'Client'
    ).toString();

    final String roomName = (
      json['out_room_name'] ?? 
      json['room_name'] ?? 
      roomData?['name_en'] ?? 
      roomData?['name'] ?? 
      'Gaming Station'
    ).toString();

    final String? rawPhone = (
      json['out_user_phone'] ?? 
      json['user_phone'] ?? 
      json['userPhone'] ?? 
      json['phone'] ?? 
      profileData?['phone'] ?? 
      profileData?['user_phone'] ?? 
      profileData?['mobile']
    )?.toString().trim();

    final String? userPhone = (rawPhone != null && rawPhone.isNotEmpty && rawPhone != 'null' && rawPhone != 'No Phone')
        ? rawPhone
        : null;

    final String? rawEmail = (
      json['out_user_email'] ?? 
      json['user_email'] ?? 
      json['userEmail'] ?? 
      json['email'] ?? 
      profileData?['email'] ?? 
      profileData?['user_email']
    )?.toString().trim();

    final String? userEmail = (rawEmail != null && rawEmail.isNotEmpty && rawEmail != 'null')
        ? rawEmail
        : null;

    String statusStr = (
      json['out_booking_status'] ?? 
      json['status'] ?? 
      json['booking_status'] ?? 
      'pending'
    ).toString();

    BookingStatus status = BookingStatusX.fromString(statusStr);

    String paymentStatusStr = (
      json['out_payment_status'] ?? 
      json['payment_status'] ?? 
      'unpaid'
    ).toString().trim().toLowerCase();

    PaymentStatus paymentStatus;
    switch (paymentStatusStr) {
      case 'paid':
      case 'completed':
        paymentStatus = PaymentStatus.paid;
        break;
      case 'refunded':
        paymentStatus = PaymentStatus.refunded;
        break;
      default:
        paymentStatus = PaymentStatus.unpaid;
    }

    final double? addonsPrice = json['addons_price'] != null
        ? parseDouble(json['addons_price'])
        : (json['out_addons_price'] != null ? parseDouble(json['out_addons_price']) : null);

    final List<Map<String, dynamic>> parsedCanteenOrders = () {
      dynamic rawOrders = json['canteen_orders'] ?? json['out_canteen_orders'];
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
    }();

    final List<Map<String, dynamic>> parsedExtras = () {
      List<Map<String, dynamic>> itemsList = [];

      // 1. Process canteen_orders if present
      if (parsedCanteenOrders.isNotEmpty) {
        for (var order in parsedCanteenOrders) {
          bool extractedFromOrderItems = false;

          // 1a. Check canteen_order_items table join first (normalized extras table join)
          dynamic orderItemsJoin = order['canteen_order_items'];
          if (orderItemsJoin is String && orderItemsJoin.trim().isNotEmpty) {
            try {
              orderItemsJoin = jsonDecode(orderItemsJoin);
            } catch (_) {}
          }
          if (orderItemsJoin is List && orderItemsJoin.isNotEmpty) {
            for (var orderItem in orderItemsJoin) {
              if (orderItem is Map) {
                final extraData = orderItem['extras'] is Map ? orderItem['extras'] as Map : {};
                final nameAr = extraData['name_ar'] ?? extraData['name'] ?? orderItem['name_ar'] ?? orderItem['name'];
                final nameEn = extraData['name_en'] ?? extraData['name'] ?? orderItem['name_en'] ?? orderItem['name'];
                final qty = (orderItem['quantity'] ?? orderItem['qty'] as num?)?.toInt() ?? 1;
                final price = (orderItem['unit_price'] ?? orderItem['price'] ?? extraData['price'] as num?)?.toDouble() ?? 0.0;

                itemsList.add({
                  'id': (orderItem['id'] ?? extraData['id'])?.toString(),
                  'extra_id': (orderItem['extra_id'] ?? extraData['id'])?.toString(),
                  'name': nameAr ?? nameEn ?? 'صنف',
                  'name_ar': nameAr ?? 'صنف',
                  'name_en': nameEn ?? 'Item',
                  'quantity': qty,
                  'price': price,
                  'unit_price': price,
                  'total_price': price * qty,
                });
                extractedFromOrderItems = true;
              }
            }
          }

          // 1b. Fallback to order['items'] JSON if canteen_order_items is empty
          if (!extractedFromOrderItems) {
            dynamic rawItems = order['items'];
            if (rawItems is String && rawItems.trim().isNotEmpty) {
              try {
                rawItems = jsonDecode(rawItems);
              } catch (_) {}
            }
            if (rawItems is List) {
              for (var it in rawItems) {
                if (it is Map) {
                  itemsList.add(Map<String, dynamic>.from(it));
                }
              }
            }
          }
        }
      }

      // 2. Process json['extras'], json['booking_items'], json['canteen_items'], json['items'], json['out_extras']
      dynamic rawExtras = json['extras'] ?? json['booking_items'] ?? json['canteen_items'] ?? json['items'] ?? json['out_extras'];
      if (rawExtras is String && rawExtras.trim().isNotEmpty) {
        try {
          rawExtras = jsonDecode(rawExtras);
        } catch (_) {}
      }
      if (rawExtras is List) {
        for (var e in rawExtras) {
          if (e is Map) {
            itemsList.add(Map<String, dynamic>.from(e));
          }
        }
      } else if (rawExtras is Map) {
        itemsList.add(Map<String, dynamic>.from(rawExtras));
      }

      return itemsList;
    }();

    return BookingModel(
      id: (json['out_booking_id'] ?? json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
      loungeId: (json['lounge_id'] ?? '').toString(),
      roomId: (json['room_id'] ?? '').toString(),
      loungeName: (json['out_lounge_name'] ?? json['lounge_name'] ?? loungeData?['name'] ?? '').toString(),
      loungeLocation: (json['lounge_location'] ?? loungeData?['location'] ?? '').toString(),
      roomName: roomName,
      controllersCount: parseInt(json['controllers_count'] ?? roomData?['controllers_count'], 0),
      screenSize: (json['screen_size'] ?? roomData?['screen_size'] ?? '').toString(),
      date: DateTime.parse(json['out_booking_date'] ?? json['date'] ?? DateTime.now().toIso8601String()),
      startTime: (json['out_start_time'] ?? json['start_time'] ?? '').toString(),
      endTime: (json['out_end_time'] ?? json['end_time'] ?? '').toString(),
      durationMinutes: parseInt(json['duration_minutes'] ?? (json['duration_hours'] != null ? (parseDouble(json['duration_hours']) * 60).round() : null), 60),
      status: status,
      paymentStatus: paymentStatus,
      totalPrice: parseDouble(json['out_total_price'] ?? json['total_price']),
      addonsPrice: addonsPrice,
      voucherDiscount: json['voucher_discount'] != null ? parseDouble(json['voucher_discount']) : null,
      voucherCode: json['voucher_code']?.toString(),
      discountAmount: json['discount_amount'] != null ? parseDouble(json['discount_amount']) : null,
      discountPercentage: json['discount_percentage'] != null ? parseDouble(json['discount_percentage']) : null,
      discountReason: json['discount_reason']?.toString(),
      extras: parsedExtras,
      canteenOrders: parsedCanteenOrders,
      lat: () {
        final val = json['latitude'] ?? json['lat'] ?? loungeData?['latitude'] ?? loungeData?['lat'];
        if (val != null) return parseDouble(val);
        final locPoint = json['location_point'] ?? loungeData?['location_point'];
        if (locPoint is Map && locPoint['coordinates'] is List && (locPoint['coordinates'] as List).length >= 2) {
          return parseDouble((locPoint['coordinates'] as List)[1]);
        }
        if (locPoint is String) {
          final match = RegExp(r'POINT\s*\(\s*([-\d.]+)\s+([-\d.]+)\s*\)', caseSensitive: false).firstMatch(locPoint);
          if (match != null) return double.tryParse(match.group(2) ?? '');
        }
        return null;
      }(),
      lng: () {
        final val = json['longitude'] ?? json['lng'] ?? loungeData?['longitude'] ?? loungeData?['lng'];
        if (val != null) return parseDouble(val);
        final locPoint = json['location_point'] ?? loungeData?['location_point'];
        if (locPoint is Map && locPoint['coordinates'] is List && (locPoint['coordinates'] as List).length >= 2) {
          return parseDouble((locPoint['coordinates'] as List)[0]);
        }
        if (locPoint is String) {
          final match = RegExp(r'POINT\s*\(\s*([-\d.]+)\s+([-\d.]+)\s*\)', caseSensitive: false).firstMatch(locPoint);
          if (match != null) return double.tryParse(match.group(1) ?? '');
        }
        return null;
      }(),
      shiftId: json['shift_id']?.toString(),
      playMode: (json['play_mode'] ?? json['playMode'])?.toString(),
      roomPrice: (json['room_price'] ?? json['roomPrice']) != null
          ? parseDouble(json['room_price'] ?? json['roomPrice'])
          : null,
      visitNumber: () {
        final raw = json['visit_number'] ?? json['out_visit_number'] ?? json['visitNumber'];
        if (raw != null) {
          final val = parseInt(raw, 0);
          return val > 0 ? val : null;
        }
        return null;
      }(),
      paymentMethod: (json['payment_method'] ?? json['out_payment_method'])?.toString(),
      receiptUrl: (json['receipt_url'] ?? json['out_receipt_url'] ?? json['receipt_path'])?.toString(),
      expiresAt: json['expires_at'] != null 
          ? DateTime.tryParse(json['expires_at'].toString()) 
          : (json['out_expires_at'] != null ? DateTime.tryParse(json['out_expires_at'].toString()) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'room_id': roomId,
      'lounge_id': loungeId,
      'date': date.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_time': endTime,
      'duration_minutes': durationMinutes,
      'room_price': roomPrice ?? totalPrice,
      'total_price': totalPrice,
      if (addonsPrice != null) 'addons_price': addonsPrice,
      'status': status.toDbString(),
      'payment_status': paymentStatus.name,
      'user_name': userName,
      'user_phone': userPhone,
      'room_name': roomName,
      if (voucherDiscount != null) 'voucher_discount': voucherDiscount,
      if (voucherCode != null && voucherCode!.isNotEmpty) 'voucher_code': voucherCode,
      'discount_amount': discountAmount,
      'discount_percentage': discountPercentage,
      'discount_reason': discountReason,
      if (shiftId != null) 'shift_id': shiftId,
      if (playMode != null) 'play_mode': playMode,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (receiptUrl != null) 'receipt_url': receiptUrl,
      if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
    };
  }
}
