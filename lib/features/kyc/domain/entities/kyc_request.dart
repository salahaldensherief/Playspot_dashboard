import 'package:equatable/equatable.dart';

class KycRequest extends Equatable {
  final String submissionId;
  final int revision;
  final String loungeId;
  final Map<String, dynamic> snapshot;
  final String userId;
  final String ownerName;
  final String ownerEmail;
  final String ownerPhone;
  final String loungeName;
  final String idDocumentUrl;
  final String? businessDocumentUrl;
  final String status;
  final String? notes;
  final DateTime? createdAt;

  const KycRequest({
    this.submissionId = '',
    this.revision = 0,
    this.loungeId = '',
    this.snapshot = const {},
    required this.userId,
    required this.ownerName,
    required this.ownerEmail,
    this.ownerPhone = '',
    required this.loungeName,
    required this.idDocumentUrl,
    this.businessDocumentUrl,
    this.status = 'pending',
    this.notes,
    this.createdAt,
  });

  factory KycRequest.fromJson(Map<String, dynamic> json) {
    return KycRequest(
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      loungeId: json['lounge_id']?.toString() ?? '',
      snapshot: json['snapshot'] is Map
          ? Map<String, dynamic>.from(json['snapshot'] as Map)
          : const {},
      submissionId: (json['submission_id'] ?? json['id'] ?? '').toString(),
      userId: (json['owner_id'] ?? json['user_id'] ?? json['userId'] ?? '')
          .toString(),
      ownerName:
          (json['owner_name'] ??
                  json['full_name'] ??
                  json['userName'] ??
                  'Pending Owner')
              .toString(),
      ownerEmail: (json['owner_email'] ?? json['email'] ?? '').toString(),
      ownerPhone:
          (json['owner_phone'] ?? json['phone'] ?? json['user_phone'] ?? '')
              .toString(),
      loungeName: (json['lounge_name'] ?? json['loungeName'] ?? 'Lounge')
          .toString(),
      idDocumentUrl: (json['id_document_url'] ?? json['id_card_url'] ?? '')
          .toString(),
      businessDocumentUrl:
          json['business_document_url'] ?? json['business_doc_url'],
      status: (json['status'] ?? 'pending').toString(),
      notes: json['notes']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  @override
  List<Object?> get props => [
    submissionId,
    revision,
    loungeId,
    snapshot,
    userId,
    ownerName,
    ownerEmail,
    ownerPhone,
    loungeName,
    idDocumentUrl,
    businessDocumentUrl,
    status,
    notes,
    createdAt,
  ];
}
