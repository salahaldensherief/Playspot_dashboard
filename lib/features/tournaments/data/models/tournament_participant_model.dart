import '../../domain/entities/tournament_participant_entity.dart';

class TournamentParticipantModel extends TournamentParticipantEntity {
  const TournamentParticipantModel({
    required super.id,
    required super.tournamentId,
    required super.userId,
    required super.userName,
    super.userPhone,
    super.userEmail,
    required super.paymentStatus,
    super.receiptPath,
    super.signedReceiptUrl,
    super.rejectionReason,
    super.isCheckedIn = false,
    super.checkedInAt,
    required super.registeredAt,
  });

  factory TournamentParticipantModel.fromJson(Map<String, dynamic> json) {
    String userNameVal = 'لاعب';
    String? phoneVal;
    String? emailVal;

    if (json['profiles'] != null && json['profiles'] is Map) {
      userNameVal = json['profiles']['full_name'] as String? ?? 'لاعب';
      phoneVal = json['profiles']['phone'] as String?;
      emailVal = json['profiles']['email'] as String?;
    } else {
      userNameVal = json['user_name'] as String? ?? 'لاعب';
      phoneVal = json['user_phone'] as String?;
      emailVal = json['user_email'] as String?;
    }

    return TournamentParticipantModel(
      id: json['id'] as String? ?? '',
      tournamentId: json['tournament_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      userName: userNameVal,
      userPhone: phoneVal,
      userEmail: emailVal,
      paymentStatus: ParticipantPaymentStatus.fromString(json['payment_status'] as String?),
      receiptPath: json['receipt_path'] as String? ?? json['receipt_url'] as String?,
      signedReceiptUrl: json['signed_receipt_url'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      isCheckedIn: json['is_checked_in'] as bool? ?? false,
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.tryParse(json['checked_in_at'].toString())
          : null,
      registeredAt: json['registered_at'] != null
          ? DateTime.tryParse(json['registered_at'].toString()) ?? DateTime.now()
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
              : DateTime.now()),
    );
  }

  TournamentParticipantModel copyWithSignedUrl(String signedUrl) {
    return TournamentParticipantModel(
      id: id,
      tournamentId: tournamentId,
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      userEmail: userEmail,
      paymentStatus: paymentStatus,
      receiptPath: receiptPath,
      signedReceiptUrl: signedUrl,
      rejectionReason: rejectionReason,
      isCheckedIn: isCheckedIn,
      checkedInAt: checkedInAt,
      registeredAt: registeredAt,
    );
  }
}
