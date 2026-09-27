import 'package:equatable/equatable.dart';

class SupportTicketEntity extends Equatable {
  final String id;
  final String? userId;
  final String userName;
  final String userPhone;
  final String issueType;
  final String message;
  final String status; // 'new', 'in_progress', 'resolved'
  final String? adminNotes;
  final String? resolvedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  const SupportTicketEntity({
    required this.id,
    this.userId,
    required this.userName,
    required this.userPhone,
    required this.issueType,
    required this.message,
    required this.status,
    this.adminNotes,
    this.resolvedBy,
    this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userPhone,
        issueType,
        message,
        status,
        adminNotes,
        resolvedBy,
        createdAt,
        updatedAt,
        resolvedAt,
      ];
}
