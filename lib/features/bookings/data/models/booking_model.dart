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
    super.durationHours = 0.0,
    required super.status,
    super.paymentStatus,
    required super.totalPrice,
    super.voucherDiscount,
    super.extras = const [],
    super.mapsLink,
    super.lat,
    super.lng,
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

    // جلب البيانات مع دعم مسميات الـ RPC الجديدة (out_) والمسميات القديمة
    final profileData = json['profiles'] as Map<String, dynamic>?;
    final roomData = json['rooms'] as Map<String, dynamic>?;
    final loungeData = json['lounges'] as Map<String, dynamic>?;

    final String userName = (
      json['out_user_name'] ?? 
      json['user_name'] ?? 
      profileData?['full_name'] ?? 
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

    final String userPhone = (
      json['out_user_phone'] ?? 
      json['user_phone'] ?? 
      json['phone'] ?? 
      profileData?['phone'] ?? 
      'No Phone'
    ).toString();

    String statusStr = (
      json['out_booking_status'] ?? 
      json['status'] ?? 
      json['booking_status'] ?? 
      'pending'
    ).toString().trim().toLowerCase();

    BookingStatus status;
    switch (statusStr) {
      case 'pending': status = BookingStatus.pending; break;
      case 'upcoming': status = BookingStatus.upcoming; break;
      case 'completed': status = BookingStatus.completed; break;
      case 'cancelled': status = BookingStatus.cancelled; break;
      default: status = BookingStatus.pending;
    }

    return BookingModel(
      id: (json['out_booking_id'] ?? json['id']).toString(),
      userId: json['user_id']?.toString() ?? '',
      userName: userName,
      userEmail: (json['out_user_email'] ?? json['user_email'] ?? profileData?['email'])?.toString(),
      userPhone: userPhone,
      loungeId: json['lounge_id']?.toString() ?? '',
      roomId: json['room_id']?.toString() ?? '',
      loungeName: (json['out_lounge_name'] ?? json['lounge_name'] ?? loungeData?['name']) ?? '',
      loungeLocation: (json['lounge_location'] ?? loungeData?['location']) ?? '',
      roomName: roomName,
      controllersCount: parseInt(json['controllers_count'] ?? roomData?['controllers_count'], 0),
      screenSize: (json['screen_size'] ?? roomData?['screen_size'])?.toString() ?? '',
      date: DateTime.parse(json['out_booking_date'] ?? json['date'] ?? DateTime.now().toIso8601String()),
      startTime: json['out_start_time'] ?? json['start_time'] ?? '',
      endTime: json['out_end_time'] ?? json['end_time'] ?? '',
      durationHours: parseDouble(json['duration_hours']),
      status: status,
      paymentStatus: (json['out_payment_status'] ?? json['payment_status'])?.toString(),
      totalPrice: parseDouble(json['out_total_price'] ?? json['total_price']),
      voucherDiscount: json['voucher_discount'] != null ? parseDouble(json['voucher_discount']) : null,
      extras: List<Map<String, dynamic>>.from(json['out_booking_extras'] ?? json['booking_extras'] ?? json['extras'] ?? []),
      mapsLink: (json['maps_link'] ?? loungeData?['maps_link'])?.toString(),
      lat: (json['lat'] ?? loungeData?['lat']) != null ? parseDouble(json['lat'] ?? loungeData?['lat']) : null,
      lng: (json['lng'] ?? loungeData?['lng']) != null ? parseDouble(json['lng'] ?? loungeData?['lng']) : null,
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
      'total_price': totalPrice,
      'status': status.name,
      'user_name': userName,
      'user_phone': userPhone,
      'room_name': roomName,
      'extras': extras,
    };
  }
}
