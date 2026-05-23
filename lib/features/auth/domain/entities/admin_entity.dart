import 'package:equatable/equatable.dart';

enum AdminRole { superAdmin, loungeAdmin }

class AdminEntity extends Equatable {
  final String id;
  final String userId;
  final String? loungeId;
  final AdminRole role;
  final String name;
  final String email;
  final String? avatarUrl;

  const AdminEntity({
    required this.id,
    required this.userId,
    this.loungeId,
    required this.role,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  bool get isSuperAdmin => role == AdminRole.superAdmin;

  @override
  List<Object?> get props => [id, userId, loungeId, role, name, email, avatarUrl];
}
