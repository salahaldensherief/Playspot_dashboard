import 'package:equatable/equatable.dart';

enum ParticipantPaymentStatus {
  pending,
  approved,
  rejected,
  cashPending,
  unpaid,
  refundPending,
  cancelled,
  unknown;

  static ParticipantPaymentStatus fromString(String? value) {
    switch (value) {
      case 'approved':
      case 'paid':
        return ParticipantPaymentStatus.approved;
      case 'rejected':
        return ParticipantPaymentStatus.rejected;
      case 'cash_pending':
        return ParticipantPaymentStatus.cashPending;
      case 'pending':
        return ParticipantPaymentStatus.pending;
      case 'unpaid':
        return ParticipantPaymentStatus.unpaid;
      case 'refund_pending':
        return ParticipantPaymentStatus.refundPending;
      case 'cancelled':
        return ParticipantPaymentStatus.cancelled;
      default:
        return ParticipantPaymentStatus.unknown;
    }
  }

  String toDbString() {
    switch (this) {
      case ParticipantPaymentStatus.approved:
        return 'paid';
      case ParticipantPaymentStatus.rejected:
        return 'rejected';
      case ParticipantPaymentStatus.cashPending:
        return 'cash_pending';
      case ParticipantPaymentStatus.pending:
        return 'pending';
      case ParticipantPaymentStatus.unpaid:
        return 'unpaid';
      case ParticipantPaymentStatus.refundPending:
        return 'refund_pending';
      case ParticipantPaymentStatus.cancelled:
        return 'cancelled';
      case ParticipantPaymentStatus.unknown:
        return 'unknown';
    }
  }
}

enum ParticipantStatus {
  registered,
  pendingPayment,
  confirmed,
  checkedIn,
  waitlist,
  eliminated,
  expired,
  cancelled,
  withdrawn,
  noShow,
  unknown;

  static ParticipantStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'registered':
        return ParticipantStatus.registered;
      case 'pending_payment':
        return ParticipantStatus.pendingPayment;
      case 'confirmed':
      case 'approved':
        return ParticipantStatus.confirmed;
      case 'waitlist':
        return ParticipantStatus.waitlist;
      case 'checked_in':
        return ParticipantStatus.checkedIn;
      case 'eliminated':
        return ParticipantStatus.eliminated;
      case 'cancelled':
        return ParticipantStatus.cancelled;
      case 'no_show':
        return ParticipantStatus.noShow;
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
        return 'unknown';
      case ParticipantStatus.pendingPayment:
        return 'pending_payment';
      case ParticipantStatus.checkedIn:
        return 'checked_in';
      case ParticipantStatus.eliminated:
        return 'eliminated';
      case ParticipantStatus.cancelled:
        return 'cancelled';
      case ParticipantStatus.noShow:
        return 'no_show';
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

  bool get isPaymentApproved =>
      paymentStatus == ParticipantPaymentStatus.approved;
  bool get isPaymentPending =>
      paymentStatus == ParticipantPaymentStatus.pending;
  bool get isWaitlist => participantStatus == ParticipantStatus.waitlist;
  bool get isWithdrawn => participantStatus == ParticipantStatus.withdrawn;
  bool get isExpired => participantStatus == ParticipantStatus.expired;
  bool get isConfirmed => participantStatus == ParticipantStatus.confirmed;
  bool get canRecordCash =>
      (participantStatus == ParticipantStatus.pendingPayment ||
          participantStatus == ParticipantStatus.registered) &&
      (paymentStatus == ParticipantPaymentStatus.unpaid ||
          paymentStatus == ParticipantPaymentStatus.rejected ||
          paymentStatus == ParticipantPaymentStatus.cashPending);
  bool get canWithdraw =>
      participantStatus == ParticipantStatus.registered ||
      participantStatus == ParticipantStatus.pendingPayment ||
      participantStatus == ParticipantStatus.confirmed ||
      participantStatus == ParticipantStatus.checkedIn ||
      participantStatus == ParticipantStatus.waitlist;

  TournamentParticipantEntity copyWith({
    String? id,
    String? tournamentId,
    String? userId,
    String? userName,
    String? userPhone,
    String? userEmail,
    ParticipantPaymentStatus? paymentStatus,
    ParticipantStatus? participantStatus,
    String? receiptPath,
    String? signedReceiptUrl,
    String? rejectionReason,
    bool? isCheckedIn,
    DateTime? checkedInAt,
    DateTime? registeredAt,
  }) {
    return TournamentParticipantEntity(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userEmail: userEmail ?? this.userEmail,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      participantStatus: participantStatus ?? this.participantStatus,
      receiptPath: receiptPath ?? this.receiptPath,
      signedReceiptUrl: signedReceiptUrl ?? this.signedReceiptUrl,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      registeredAt: registeredAt ?? this.registeredAt,
    );
  }

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
