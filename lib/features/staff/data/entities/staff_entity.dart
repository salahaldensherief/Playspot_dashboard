import 'package:equatable/equatable.dart';

class StaffEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role; // 'lounge_owner', 'cashier', 'manager'
  final String loungeId;
  final bool isActive;
  final DateTime createdAt;

  const StaffEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.loungeId,
    this.isActive = true,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, email, phone, role, loungeId, isActive, createdAt];

  StaffEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? loungeId,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return StaffEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      loungeId: loungeId ?? this.loungeId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
