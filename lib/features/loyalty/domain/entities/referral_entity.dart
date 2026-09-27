import 'package:equatable/equatable.dart';

class ReferralEntity extends Equatable {
  final String id;
  final String inviterId;
  final String inviterName;
  final String inviterEmail;
  final String inviteeId;
  final String inviteeName;
  final String inviteeEmail;
  final DateTime? createdAt;
  final String status;
  final bool rewardIssued;
  final int inviterPoints;
  final int inviteePoints;

  const ReferralEntity({
    required this.id,
    required this.inviterId,
    required this.inviterName,
    required this.inviterEmail,
    required this.inviteeId,
    required this.inviteeName,
    required this.inviteeEmail,
    this.createdAt,
    required this.status,
    required this.rewardIssued,
    required this.inviterPoints,
    required this.inviteePoints,
  });

  @override
  List<Object?> get props => [
        id,
        inviterId,
        inviterName,
        inviterEmail,
        inviteeId,
        inviteeName,
        inviteeEmail,
        createdAt,
        status,
        rewardIssued,
        inviterPoints,
        inviteePoints,
      ];
}
