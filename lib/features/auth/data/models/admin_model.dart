import '../../domain/entities/admin_entity.dart';

class AdminModel extends AdminEntity {
  const AdminModel({
    required String id,
    required String userId,
    String? loungeId,
    required AdminRole role,
    required String name,
    required String email,
    String? avatarUrl,
  }) : super(
          id: id,
          userId: userId,
          loungeId: loungeId,
          role: role,
          name: name,
          email: email,
          avatarUrl: avatarUrl,
        );

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    final userData = json['users'] as Map<String, dynamic>?;

    return AdminModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      loungeId: json['lounge_id'] as String?,
      role: json['role'] == 'super_admin' ? AdminRole.superAdmin : AdminRole.loungeAdmin,
      name: userData?['name'] as String? ?? json['name'] as String? ?? 'Unknown',
      email: userData?['email'] as String? ?? json['email'] as String? ?? '',
      avatarUrl: userData?['avatar_url'] as String? ?? json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'lounge_id': loungeId,
      'role': role == AdminRole.superAdmin ? 'super_admin' : 'lounge_admin',
    };
  }
}
