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
    super.isFirstBooking = false,
    super.senderWalletPhone,
    super.checkedInAt,
    super.cancellationReason,
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

    final String? rawUserName = (
      json['out_user_name'] ?? 
      json['user_name'] ?? 
      json['userName'] ?? 
      profileData?['full_name'] ?? 
      profileData?['name'] ?? 
      json['full_name']
    )?.toString().trim();
    final String userName = (rawUserName != null && rawUserName.isNotEmpty && rawUserName != 'null') ? rawUserName : '';

    final String? rawRoomName = (
      json['out_room_name'] ?? 
      json['room_name'] ?? 
      roomData?['name_en'] ?? 
      roomData?['name']
    )?.toString().trim();
    final String roomName = (rawRoomName != null && rawRoomName.isNotEmpty && rawRoomName != 'null') ? rawRoomName : '';

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

    final String paymentMethodStr = (json['payment_method'] ?? json['out_payment_method'] ?? 'cash').toString().toLowerCase();
    final bool isCash = paymentMethodStr == 'cash' || paymentMethodStr.isEmpty;

    if (isCash && paymentStatus != PaymentStatus.paid && (status == BookingStatus.upcoming || statusStr == 'upcoming')) {
      status = BookingStatus.pending;
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

      void addNormalizedItem(Map map) {
        final String? nameAr = map['name_ar']?.toString().trim();
        final String? nameEn = map['name_en']?.toString().trim();
        final String? nameDefault = map['name']?.toString().trim();
        final String? rawTitle = (map['title'] ?? map['item_name'] ?? map['extra_name'] ?? map['product_name'])?.toString().trim();

        final resolvedName = (nameAr != null && nameAr.isNotEmpty && nameAr != 'null')
            ? nameAr
            : ((nameEn != null && nameEn.isNotEmpty && nameEn != 'null')
                ? nameEn
                : ((nameDefault != null && nameDefault.isNotEmpty && nameDefault != 'null' && nameDefault != 'canteen_order')
                    ? nameDefault
                    : ((rawTitle != null && rawTitle.isNotEmpty && rawTitle != 'null') ? rawTitle : 'صنف')));

        final qty = (map['quantity'] ?? map['qty'] ?? map['count'] as num?)?.toInt() ?? 1;
        final unitPrice = (map['unit_price'] ?? map['price'] ?? map['item_price'] as num?)?.toDouble() ?? 0.0;
        final givenTotal = (map['total_price'] ?? map['total'] ?? map['amount'] as num?)?.toDouble();
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

      // 1. Process json['items'], json['booking_items'], json['extras'], json['canteen_items'], json['out_extras']
      dynamic rawExtras = json['items'] ?? json['booking_items'] ?? json['extras'] ?? json['canteen_items'] ?? json['out_extras'];
      if (rawExtras is String && rawExtras.trim().isNotEmpty) {
        try {
          rawExtras = jsonDecode(rawExtras);
        } catch (_) {}
      }
      if (rawExtras is List) {
        for (var e in rawExtras) {
          if (e is Map) {
            addNormalizedItem(e);
          }
        }
      } else if (rawExtras is Map) {
        addNormalizedItem(rawExtras);
      }

      // 2. Process canteen_orders if present
      if (parsedCanteenOrders.isNotEmpty) {
        for (var order in parsedCanteenOrders) {
          final List<dynamic> sourceLists = [
            order['items'],
            order['canteen_order_items'],
            order['canteen_items'],
          ];

          for (var rawItems in sourceLists) {
            if (rawItems is String && rawItems.trim().isNotEmpty) {
              try {
                rawItems = jsonDecode(rawItems);
              } catch (_) {}
            }
            if (rawItems is List) {
              for (var it in rawItems) {
                if (it is Map) {
                  addNormalizedItem(it);
                }
              }
            }
          }
        }
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
      receiptUrl: () {
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
      }(),
      expiresAt: json['expires_at'] != null 
          ? DateTime.tryParse(json['expires_at'].toString()) 
          : (json['out_expires_at'] != null ? DateTime.tryParse(json['out_expires_at'].toString()) : null),
      isFirstBooking: json['is_first_booking'] ?? false,
      senderWalletPhone: (json['sender_wallet_phone'] ?? json['sender_phone'])?.toString(),
      checkedInAt: json['checked_in_at'] != null ? DateTime.tryParse(json['checked_in_at'].toString()) : null,
      cancellationReason: json['cancellation_reason']?.toString(),
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
      'is_first_booking': isFirstBooking,
      if (senderWalletPhone != null) 'sender_wallet_phone': senderWalletPhone,
      if (checkedInAt != null) 'checked_in_at': checkedInAt!.toIso8601String(),
      if (cancellationReason != null) 'cancellation_reason': cancellationReason,
    };
  }
}
