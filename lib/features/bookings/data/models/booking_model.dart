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
    super.voucherDiscount,
    super.discountAmount,
    super.discountPercentage,
    super.discountReason,
    super.extras = const [],
    super.lat,
    super.lng,
    super.shiftId,
    super.playMode,
    super.roomPrice,
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
      voucherDiscount: json['voucher_discount'] != null ? parseDouble(json['voucher_discount']) : null,
      discountAmount: json['discount_amount'] != null ? parseDouble(json['discount_amount']) : null,
      discountPercentage: json['discount_percentage'] != null ? parseDouble(json['discount_percentage']) : null,
      discountReason: json['discount_reason']?.toString(),
      extras: () {
        dynamic rawExtras = json['booking_items'] ??
            json['canteen_items'] ??
            json['out_booking_extras'] ??
            json['booking_extras'] ??
            json['extras'];

        if (rawExtras is List) {
          return rawExtras
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return <Map<String, dynamic>>[];
      }(),
      lat: (json['latitude'] ?? json['lat'] ?? loungeData?['latitude'] ?? loungeData?['lat']) != null
          ? parseDouble(json['latitude'] ?? json['lat'] ?? loungeData?['latitude'] ?? loungeData?['lat'])
          : null,
      lng: (json['longitude'] ?? json['lng'] ?? loungeData?['longitude'] ?? loungeData?['lng']) != null
          ? parseDouble(json['longitude'] ?? json['lng'] ?? loungeData?['longitude'] ?? loungeData?['lng'])
          : null,
      shiftId: json['shift_id']?.toString(),
      playMode: (json['play_mode'] ?? json['playMode'])?.toString(),
      roomPrice: (json['room_price'] ?? json['roomPrice']) != null
          ? parseDouble(json['room_price'] ?? json['roomPrice'])
          : null,
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
      'total_price': totalPrice,
      'status': status.toDbString(),
      'payment_status': paymentStatus.name,
      'user_name': userName,
      'user_phone': userPhone,
      'room_name': roomName,
      'discount_amount': discountAmount,
      'discount_percentage': discountPercentage,
      'discount_reason': discountReason,
      if (shiftId != null) 'shift_id': shiftId,
      if (playMode != null) 'play_mode': playMode,
      if (roomPrice != null) 'room_price': roomPrice,
    };
  }
}
