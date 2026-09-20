import 'package:equatable/equatable.dart';

enum UserBanRequestStatus {
  pending,
  approvedLoungeOnly,
  approvedGlobal,
  rejected;

  String toDbString() {
    switch (this) {
      case UserBanRequestStatus.pending:
        return 'pending';
      case UserBanRequestStatus.approvedLoungeOnly:
        return 'approved_lounge_only';
      case UserBanRequestStatus.approvedGlobal:
        return 'approved_global';
      case UserBanRequestStatus.rejected:
        return 'rejected';
    }
  }

  static UserBanRequestStatus fromString(String? val) {
    if (val == null) return UserBanRequestStatus.pending;
    final clean = val.trim().toLowerCase();
    switch (clean) {
      case 'approved_lounge_only':
      case 'lounge_only':
        return UserBanRequestStatus.approvedLoungeOnly;
      case 'approved_global':
      case 'global':
        return UserBanRequestStatus.approvedGlobal;
      case 'rejected':
        return UserBanRequestStatus.rejected;
      case 'pending':
      default:
        return UserBanRequestStatus.pending;
    }
  }

  String toDisplayString() {
    switch (this) {
      case UserBanRequestStatus.pending:
        return 'قيد المراجعة';
      case UserBanRequestStatus.approvedLoungeOnly:
        return 'محظور من الصالة فقط';
      case UserBanRequestStatus.approvedGlobal:
        return 'محظور كلياً من التطبيق';
      case UserBanRequestStatus.rejected:
        return 'تم رفض البلاغ';
    }
  }
}

class UserBanRequest extends Equatable {
  final String id;
  final String loungeId;
  final String userId;
  final String? bookingId;
  final String reason;
  final String? evidenceNotes;
  final UserBanRequestStatus status;
  final String? adminNotes;
  final DateTime createdAt;

  // Joined display attributes
  final String? userName;
  final String? userPhone;
  final String? userEmail;
  final String? loungeName;

  const UserBanRequest({
    required this.id,
    required this.loungeId,
    required this.userId,
    this.bookingId,
    required this.reason,
    this.evidenceNotes,
    this.status = UserBanRequestStatus.pending,
    this.adminNotes,
    required this.createdAt,
    this.userName,
    this.userPhone,
    this.userEmail,
    this.loungeName,
  });

  @override
  List<Object?> get props => [
        id,
        loungeId,
        userId,
        bookingId,
        reason,
        evidenceNotes,
        status,
        adminNotes,
        createdAt,
        userName,
        userPhone,
        userEmail,
        loungeName,
      ];
}
