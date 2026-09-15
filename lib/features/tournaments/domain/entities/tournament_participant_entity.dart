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

enum ParticipantStatus {
  registered,
  confirmed,
  waitlist,
  expired,
  withdrawn,
  unknown;

  static ParticipantStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'registered':
        return ParticipantStatus.registered;
      case 'confirmed':
      case 'approved':
        return ParticipantStatus.confirmed;
      case 'waitlist':
        return ParticipantStatus.waitlist;
      case 'expired':
        return ParticipantStatus.expired;
      case 'withdrawn':
        return ParticipantStatus.withdrawn;
      default:
        return ParticipantStatus.unknown;
    }
  }

  String toDbString() {
    switch (this) {
      case ParticipantStatus.registered:
        return 'registered';
      case ParticipantStatus.confirmed:
        return 'confirmed';
      case ParticipantStatus.waitlist:
        return 'waitlist';
      case ParticipantStatus.expired:
        return 'expired';
      case ParticipantStatus.withdrawn:
        return 'withdrawn';
      case ParticipantStatus.unknown:
        return 'registered';
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
  final ParticipantStatus participantStatus;
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
    this.participantStatus = ParticipantStatus.registered,
    this.receiptPath,
    this.signedReceiptUrl,
    this.rejectionReason,
    this.isCheckedIn = false,
    this.checkedInAt,
    required this.registeredAt,
  });

  bool get isPaymentApproved => paymentStatus == ParticipantPaymentStatus.approved;
  bool get isPaymentPending => paymentStatus == ParticipantPaymentStatus.pending;
  bool get isWaitlist => participantStatus == ParticipantStatus.waitlist;
  bool get isWithdrawn => participantStatus == ParticipantStatus.withdrawn;
  bool get isExpired => participantStatus == ParticipantStatus.expired;
  bool get isConfirmed => participantStatus == ParticipantStatus.confirmed;

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        userId,
        userName,
        userPhone,
        userEmail,
        paymentStatus,
        participantStatus,
        receiptPath,
        signedReceiptUrl,
        rejectionReason,
        isCheckedIn,
        checkedInAt,
        registeredAt,
      ];
}
