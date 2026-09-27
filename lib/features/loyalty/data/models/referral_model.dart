import '../../domain/entities/referral_entity.dart';

class ReferralModel extends ReferralEntity {
  const ReferralModel({
    required super.id,
    required super.inviterId,
    required super.inviterName,
    required super.inviterEmail,
    required super.inviteeId,
    required super.inviteeName,
    required super.inviteeEmail,
    super.createdAt,
    required super.status,
    required super.rewardIssued,
    required super.inviterPoints,
    required super.inviteePoints,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    final inviterMap = json['referrer'] as Map<String, dynamic>? ?? json['inviter'] as Map<String, dynamic>? ?? {};
    final inviteeMap = json['invitee'] as Map<String, dynamic>? ?? json['referred'] as Map<String, dynamic>? ?? {};

    return ReferralModel(
      id: json['id']?.toString() ?? '',
      inviterId: json['inviter_id']?.toString() ?? json['referrer_id']?.toString() ?? '',
      inviterName: inviterMap['full_name']?.toString() ?? inviterMap['name']?.toString() ?? json['inviter_name']?.toString() ?? 'N/A',
      inviterEmail: inviterMap['email']?.toString() ?? json['inviter_email']?.toString() ?? '',
      inviteeId: json['invitee_id']?.toString() ?? json['referred_id']?.toString() ?? '',
      inviteeName: inviteeMap['full_name']?.toString() ?? inviteeMap['name']?.toString() ?? json['invitee_name']?.toString() ?? 'N/A',
      inviteeEmail: inviteeMap['email']?.toString() ?? json['invitee_email']?.toString() ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      status: json['status']?.toString() ?? 'pending',
      rewardIssued: json['reward_issued'] as bool? ?? json['is_rewarded'] as bool? ?? false,
      inviterPoints: (json['inviter_points'] as num?)?.toInt() ?? (json['referrer_points'] as num?)?.toInt() ?? 0,
      inviteePoints: (json['invitee_points'] as num?)?.toInt() ?? (json['referred_points'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inviter_id': inviterId,
      'inviter_name': inviterName,
      'inviter_email': inviterEmail,
      'invitee_id': inviteeId,
      'invitee_name': inviteeName,
      'invitee_email': inviteeEmail,
      'created_at': createdAt?.toIso8601String(),
      'status': status,
      'reward_issued': rewardIssued,
      'inviter_points': inviterPoints,
      'invitee_points': inviteePoints,
    };
  }
}
