import 'package:equatable/equatable.dart';

class KycRequest extends Equatable {
  final String userId;
  final String ownerName;
  final String ownerEmail;
  final String loungeName;
  final String idDocumentUrl;
  final String? businessDocumentUrl;

  const KycRequest({
    required this.userId,
    required this.ownerName,
    required this.ownerEmail,
    required this.loungeName,
    required this.idDocumentUrl,
    this.businessDocumentUrl,
  });

  factory KycRequest.fromJson(Map<String, dynamic> json) {
    return KycRequest(
      userId: json['user_id'] ?? '',
      ownerName: json['owner_name'] ?? '',
      ownerEmail: json['owner_email'] ?? '',
      loungeName: json['lounge_name'] ?? '',
      idDocumentUrl: json['id_document_url'] ?? '',
      businessDocumentUrl: json['business_document_url'],
    );
  }

  @override
  List<Object?> get props => [
        userId,
        ownerName,
        ownerEmail,
        loungeName,
        idDocumentUrl,
        businessDocumentUrl,
      ];
}
