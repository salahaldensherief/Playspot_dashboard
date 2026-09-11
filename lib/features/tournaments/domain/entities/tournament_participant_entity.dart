import 'package:equatable/equatable.dart';

enum ParticipantPaymentStatus {
  pending,
  approved,
  rejected,
  cashPending;

  static ParticipantPaymentStatus fromString(String? value) {
    switch (value) {
      case 'approved':
        return ParticipantPaymentStatus.approved;
      case 'rejected':
        return ParticipantPaymentStatus.rejected;
      case 'cash_pending':
        return ParticipantPaymentStatus.cashPending;
      case 'pending':
      default:
        return ParticipantPaymentStatus.pending;
    }
  }

  String toDbString() {
    switch (this) {
      case ParticipantPaymentStatus.approved:
        return 'approved';
      case ParticipantPaymentStatus.rejected:
        return 'rejected';
      case ParticipantPaymentStatus.cashPending:
        return 'cash_pending';
      case ParticipantPaymentStatus.pending:
        return 'pending';
    }
  }
}

class TournamentParticipantEntity extends Equatable {
  final String id;
  final String tournamentId;
  final String userId;
  final String userName;
  final String? userPhone;
  final String? userEmail;
  final ParticipantPaymentStatus paymentStatus;
  final String? receiptPath;
  final String? signedReceiptUrl;
  final String? rejectionReason;
  final bool isCheckedIn;
  final DateTime? checkedInAt;
  final DateTime registeredAt;

  const TournamentParticipantEntity({
    required this.id,
    required this.tournamentId,
    required this.userId,
    required this.userName,
    this.userPhone,
    this.userEmail,
    required this.paymentStatus,
    this.receiptPath,
    this.signedReceiptUrl,
    this.rejectionReason,
    this.isCheckedIn = false,
    this.checkedInAt,
    required this.registeredAt,
  });

  bool get isPaymentApproved => paymentStatus == ParticipantPaymentStatus.approved;
  bool get isPaymentPending => paymentStatus == ParticipantPaymentStatus.pending;

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        userId,
        userName,
        userPhone,
        userEmail,
        paymentStatus,
        receiptPath,
        signedReceiptUrl,
        rejectionReason,
        isCheckedIn,
        checkedInAt,
        registeredAt,
      ];
}
