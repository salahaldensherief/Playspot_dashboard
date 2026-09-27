import '../../domain/entities/support_ticket_entity.dart';

class SupportTicketModel extends SupportTicketEntity {
  const SupportTicketModel({
    required super.id,
    super.userId,
    required super.userName,
    required super.userPhone,
    required super.issueType,
    required super.message,
    required super.status,
    super.adminNotes,
    super.resolvedBy,
    super.createdAt,
    super.updatedAt,
    super.resolvedAt,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    return SupportTicketModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      userName: json['user_name'] as String? ?? '',
      userPhone: json['user_phone'] as String? ?? '',
      issueType: json['issue_type'] as String? ?? 'general',
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'new',
      adminNotes: json['admin_notes'] as String?,
      resolvedBy: json['resolved_by']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      resolvedAt: json['resolved_at'] != null ? DateTime.tryParse(json['resolved_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'user_name': userName,
      'user_phone': userPhone,
      'issue_type': issueType,
      'message': message,
      'status': status,
      if (adminNotes != null) 'admin_notes': adminNotes,
      if (resolvedBy != null) 'resolved_by': resolvedBy,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
