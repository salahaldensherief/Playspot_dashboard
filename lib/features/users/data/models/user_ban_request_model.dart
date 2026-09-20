import '../../domain/entities/user_ban_request.dart';

class UserBanRequestModel extends UserBanRequest {
  const UserBanRequestModel({
    required super.id,
    required super.loungeId,
    required super.userId,
    super.bookingId,
    required super.reason,
    super.evidenceNotes,
    super.status,
    super.adminNotes,
    required super.createdAt,
    super.userName,
    super.userPhone,
    super.userEmail,
    super.loungeName,
  });

  factory UserBanRequestModel.fromJson(Map<String, dynamic> json) {
    final profileData = json['profiles'] as Map<String, dynamic>?;
    final loungeData = json['lounges'] as Map<String, dynamic>?;

    return UserBanRequestModel(
      id: (json['id'] ?? '').toString(),
      loungeId: (json['lounge_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      bookingId: json['booking_id']?.toString(),
      reason: (json['reason'] ?? '').toString(),
      evidenceNotes: json['evidence_notes']?.toString(),
      status: UserBanRequestStatus.fromString(json['status']?.toString()),
      adminNotes: json['admin_notes']?.toString(),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      userName: (json['user_name'] ?? json['user_full_name'] ?? profileData?['full_name'] ?? profileData?['name'])?.toString(),
      userPhone: (json['user_phone'] ?? profileData?['phone'])?.toString(),
      userEmail: (json['user_email'] ?? profileData?['email'])?.toString(),
      loungeName: (json['lounge_name'] ?? loungeData?['name'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lounge_id': loungeId,
      'user_id': userId,
      if (bookingId != null && bookingId!.isNotEmpty) 'booking_id': bookingId,
      'reason': reason,
      if (evidenceNotes != null && evidenceNotes!.isNotEmpty) 'evidence_notes': evidenceNotes,
      'status': status.toDbString(),
      if (adminNotes != null && adminNotes!.isNotEmpty) 'admin_notes': adminNotes,
    };
  }
}
