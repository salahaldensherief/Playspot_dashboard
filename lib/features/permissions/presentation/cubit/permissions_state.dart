import 'package:equatable/equatable.dart';
import '../../domain/entities/permission_item_entity.dart';

enum PermissionsStatus { initial, loading, success, failure }

class PermissionsState extends Equatable {
  final PermissionsStatus status;
  final List<PermissionItemEntity> permissions;
  final Map<String, bool> userPermissions;
  final String? errorMessage;
  final String selectedRole;
  final String? userRole;

  const PermissionsState({
    required this.status,
    this.permissions = const [],
    this.userPermissions = const {},
    this.errorMessage,
    this.selectedRole = 'cashier',
    this.userRole,
  });

  factory PermissionsState.initial() => const PermissionsState(status: PermissionsStatus.initial);

  PermissionsState copyWith({
    PermissionsStatus? status,
    List<PermissionItemEntity>? permissions,
    Map<String, bool>? userPermissions,
    String? errorMessage,
    String? selectedRole,
    String? userRole,
  }) {
    return PermissionsState(
      status: status ?? this.status,
      permissions: permissions ?? this.permissions,
      userPermissions: userPermissions ?? this.userPermissions,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedRole: selectedRole ?? this.selectedRole,
      userRole: userRole ?? this.userRole,
    );
  }

  @override
  List<Object?> get props => [
        status,
        permissions,
        userPermissions,
        errorMessage,
        selectedRole,
        userRole,
      ];
}
