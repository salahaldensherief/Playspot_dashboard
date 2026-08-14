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
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: (json['out_staff_id'] ?? json['id'] ?? json['out_user_id'])?.toString() ?? '',
      name: (json['out_full_name'] ?? json['full_name'] ?? json['name'] ?? '')?.toString() ?? '',
      email: (json['out_email'] ?? json['email'] ?? '')?.toString() ?? '',
      phone: (json['out_phone'] ?? json['phone'])?.toString(),
      role: (json['out_role'] ?? json['role'])?.toString() ?? 'cashier',
      loungeId: (json['out_lounge_id'] ?? json['lounge_id'])?.toString() ?? '',
      isActive: json['is_active'] ?? json['out_is_active'] ?? true,
      createdAt: json['out_created_at'] != null
          ? DateTime.parse(json['out_created_at'].toString())
          : (json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now()),
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
    };
  }
}
