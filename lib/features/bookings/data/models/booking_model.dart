import '../../domain/entities/booking.dart';

class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.userId,
    super.userName,
    super.userEmail,
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
    required super.status,
    super.paymentStatus,
    required super.totalPrice,
    super.mapsLink,
    super.lat,
    super.lng,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // Helper to parse double safely
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    // Helper to parse int safely
    int parseInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? defaultValue;
    }

    final loungeData = json['lounges'] as Map<String, dynamic>?;
    final roomData = json['rooms'] as Map<String, dynamic>?;

    // التأكد من قراءة حالة الحجز بدقة من العمود الصحيح في الـ RPC أو الجدول
    String statusStr = (json['status'] ?? 'pending').toString().trim().toLowerCase();
    
    // إذا كانت القيمة قادمة من الـ Realtime Payload لجدول الحجز
    // Supabase يرسل أحياناً اسم العمود بالكامل
    if (json.containsKey('booking_status')) {
      statusStr = json['booking_status'].toString().trim().toLowerCase();
    }

    BookingStatus status;
    switch (statusStr) {
      case 'pending':
        status = BookingStatus.pending;
        break;
      case 'upcoming':
        status = BookingStatus.upcoming;
        break;
      case 'completed':
        status = BookingStatus.completed;
        break;
      case 'cancelled':
        status = BookingStatus.cancelled;
        break;
      default:
        // إذا لم تطابق أي حالة، نعتبرها pending كافتراضي للطلبات الجديدة
        status = BookingStatus.pending;
    }

    return BookingModel(
      id: json['id'].toString(),
      userId: json['user_id']?.toString() ?? '',
      userName: (json['user_name'] ?? json['full_name'])?.toString(),
      userEmail: json['user_email']?.toString(),
      loungeId: json['lounge_id']?.toString() ?? '',
      roomId: json['room_id']?.toString() ?? '',
      loungeName: (json['lounge_name'] ?? loungeData?['name']) ?? '',
      loungeLocation: (json['lounge_location'] ?? loungeData?['location']) ?? '',
      roomName: (json['room_name'] ?? roomData?['name_en'] ?? roomData?['name']) ?? '',
      controllersCount: parseInt(json['controllers_count'] ?? roomData?['controllers_count'], 0),
      screenSize: (json['screen_size'] ?? roomData?['screen_size'])?.toString() ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      status: status,
      paymentStatus: json['payment_status']?.toString(),
      totalPrice: parseDouble(json['total_price']),
      mapsLink: (json['maps_link'] ?? loungeData?['maps_link'])?.toString(),
      lat: (json['lat'] ?? loungeData?['lat']) != null ? parseDouble(json['lat'] ?? loungeData?['lat']) : null,
      lng: (json['lng'] ?? loungeData?['lng']) != null ? parseDouble(json['lng'] ?? loungeData?['lng']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'lounge_id': loungeId,
      'room_id': roomId,
      'date': date.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'status': status.toString().split('.').last,
      'total_price': totalPrice,
    };
  }
}
