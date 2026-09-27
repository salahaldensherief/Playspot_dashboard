import '../../domain/entities/booking.dart';
import 'booking_json_parser.dart';

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
    super.rejectionReason,
    super.cancelledBy,
    super.cancelledAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
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

    final String statusStr = (
      json['out_booking_status'] ?? 
      json['status'] ?? 
      json['booking_status'] ?? 
      'pending'
    ).toString();

    BookingStatus status = BookingStatusX.fromString(statusStr);

    final String paymentStatusStr = (
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
        ? BookingJsonParser.parseDouble(json['addons_price'])
        : (json['out_addons_price'] != null ? BookingJsonParser.parseDouble(json['out_addons_price']) : null);

    final List<Map<String, dynamic>> parsedCanteenOrders =
        BookingJsonParser.parseCanteenOrders(json['canteen_orders'] ?? json['out_canteen_orders']);

    final List<Map<String, dynamic>> parsedExtras =
        BookingJsonParser.parseExtras(json, parsedCanteenOrders);

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
      controllersCount: BookingJsonParser.parseInt(json['controllers_count'] ?? roomData?['controllers_count'], 0),
      screenSize: (json['screen_size'] ?? roomData?['screen_size'] ?? '').toString(),
      date: DateTime.parse(json['out_booking_date'] ?? json['date'] ?? DateTime.now().toIso8601String()),
      startTime: (json['out_start_time'] ?? json['start_time'] ?? '').toString(),
      endTime: (json['out_end_time'] ?? json['end_time'] ?? '').toString(),
      durationMinutes: BookingJsonParser.parseInt(json['duration_minutes'] ?? (json['duration_hours'] != null ? (BookingJsonParser.parseDouble(json['duration_hours']) * 60).round() : null), 60),
      status: status,
      paymentStatus: paymentStatus,
      totalPrice: BookingJsonParser.parseDouble(json['out_total_price'] ?? json['total_price']),
      addonsPrice: addonsPrice,
      voucherDiscount: json['voucher_discount'] != null ? BookingJsonParser.parseDouble(json['voucher_discount']) : null,
      voucherCode: json['voucher_code']?.toString(),
      discountAmount: json['discount_amount'] != null ? BookingJsonParser.parseDouble(json['discount_amount']) : null,
      discountPercentage: json['discount_percentage'] != null ? BookingJsonParser.parseDouble(json['discount_percentage']) : null,
      discountReason: json['discount_reason']?.toString(),
      extras: parsedExtras,
      canteenOrders: parsedCanteenOrders,
      lat: BookingJsonParser.parseCoordinate(json, loungeData, true),
      lng: BookingJsonParser.parseCoordinate(json, loungeData, false),
      shiftId: json['shift_id']?.toString(),
      playMode: (json['play_mode'] ?? json['playMode'])?.toString(),
      roomPrice: (json['room_price'] ?? json['roomPrice']) != null
          ? BookingJsonParser.parseDouble(json['room_price'] ?? json['roomPrice'])
          : null,
      visitNumber: () {
        final raw = json['visit_number'] ?? json['out_visit_number'] ?? json['visitNumber'];
        if (raw != null) {
          final val = BookingJsonParser.parseInt(raw, 0);
          if (val > 0) return val;
        }
        final userIdStr = (json['user_id'] ?? json['out_user_id'] ?? '').toString().trim();
        if (userIdStr.isEmpty) {
          return 1;
        }
        return null;
      }(),
      paymentMethod: (json['payment_method'] ?? json['out_payment_method'])?.toString(),
      receiptUrl: BookingJsonParser.parseReceiptUrl(json),
      expiresAt: json['expires_at'] != null 
          ? DateTime.tryParse(json['expires_at'].toString()) 
          : (json['out_expires_at'] != null ? DateTime.tryParse(json['out_expires_at'].toString()) : null),
      isFirstBooking: json['is_first_booking'] ?? false,
      senderWalletPhone: (json['sender_wallet_phone'] ?? json['sender_phone'])?.toString(),
      checkedInAt: json['checked_in_at'] != null ? DateTime.tryParse(json['checked_in_at'].toString()) : null,
      cancellationReason: json['cancellation_reason']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      cancelledBy: (json['cancelled_by'] ?? json['out_cancelled_by'])?.toString(),
      cancelledAt: json['cancelled_at'] != null 
          ? DateTime.tryParse(json['cancelled_at'].toString()) 
          : (json['out_cancelled_at'] != null ? DateTime.tryParse(json['out_cancelled_at'].toString()) : null),
    );
  }

  Map<String, dynamic> toJson() {
    final vCode = voucherCode;
    final expAt = expiresAt;
    final chkAt = checkedInAt;
    final cAt = cancelledAt;

    final map = <String, dynamic>{
      if (userId.trim().isNotEmpty) 'user_id': userId,
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
      if (userPhone != null && userPhone!.trim().isNotEmpty) 'user_phone': userPhone,
      'room_name': roomName,
      if (voucherDiscount != null) 'voucher_discount': voucherDiscount,
      if (vCode != null && vCode.trim().isNotEmpty) 'voucher_code': vCode,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (discountPercentage != null) 'discount_percentage': discountPercentage,
      if (discountReason != null && discountReason!.trim().isNotEmpty) 'discount_reason': discountReason,
      if (shiftId != null && shiftId!.trim().isNotEmpty) 'shift_id': shiftId,
      if (playMode != null && playMode!.trim().isNotEmpty) 'play_mode': playMode,
      if (paymentMethod != null && paymentMethod!.trim().isNotEmpty) 'payment_method': paymentMethod,
      if (receiptUrl != null && receiptUrl!.trim().isNotEmpty) 'receipt_url': receiptUrl,
      if (expAt != null) 'expires_at': expAt.toIso8601String(),
      'is_first_booking': isFirstBooking,
      if (senderWalletPhone != null && senderWalletPhone!.trim().isNotEmpty) 'sender_wallet_phone': senderWalletPhone,
      if (chkAt != null) 'checked_in_at': chkAt.toIso8601String(),
      if (cancellationReason != null && cancellationReason!.trim().isNotEmpty) 'cancellation_reason': cancellationReason,
      if (rejectionReason != null && rejectionReason!.trim().isNotEmpty) 'rejection_reason': rejectionReason,
      if (cancelledBy != null && cancelledBy!.trim().isNotEmpty) 'cancelled_by': cancelledBy,
      if (cAt != null) 'cancelled_at': cAt.toIso8601String(),
    };

    return map;
  }
}
