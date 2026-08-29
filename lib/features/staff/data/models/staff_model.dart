import '../entities/staff_entity.dart';

class StaffModel extends StaffEntity {
  const StaffModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    required super.role,
    required super.loungeId,
    super.isActive = true,
    required super.createdAt,
    super.nationalIdNumber,
    super.idFrontUrl,
    super.idBackUrl,
    super.avatarUrl,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: (json['staff_id'] ?? json['user_id'] ?? json['out_staff_id'] ?? json['id'])?.toString() ?? '',
      name: (json['full_name'] ?? json['out_full_name'] ?? json['name'] ?? '')?.toString() ?? '',
      email: (json['email'] ?? json['out_email'] ?? '')?.toString() ?? '',
      phone: (json['phone'] ?? json['out_phone'])?.toString(),
      role: (json['role'] ?? json['out_role'])?.toString() ?? 'cashier',
      loungeId: (json['lounge_id'] ?? json['out_lounge_id'])?.toString() ?? '',
      isActive: json['is_active'] ?? json['out_is_active'] ?? true,
      createdAt: json['out_created_at'] != null
          ? DateTime.parse(json['out_created_at'].toString())
          : (json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now()),
      nationalIdNumber: (json['national_id_number'] ?? json['out_national_id_number'])?.toString(),
      idFrontUrl: (json['id_front_url'] ?? json['out_id_front_url'] ?? json['id_document_url'])?.toString(),
      idBackUrl: (json['id_back_url'] ?? json['out_id_back_url'])?.toString(),
      avatarUrl: (json['avatar_url'] ?? json['out_avatar_url'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'lounge_id': loungeId,
      'is_active': isActive,
      'national_id_number': nationalIdNumber,
      'id_front_url': idFrontUrl,
      'id_back_url': idBackUrl,
      'avatar_url': avatarUrl,
    };
  }
}
