import 'package:equatable/equatable.dart';
import '../../domain/entities/permission_item_entity.dart';

enum PermissionsStatus { initial, loading, success, failure }

class PermissionsState extends Equatable {
  final PermissionsStatus status;
  final List<PermissionItemEntity> permissions;
  final String? errorMessage;
  final String selectedRole;

  const PermissionsState({
    required this.status,
    this.permissions = const [],
    this.errorMessage,
    this.selectedRole = 'cashier',
  });

  factory PermissionsState.initial() => const PermissionsState(status: PermissionsStatus.initial);

  PermissionsState copyWith({
    PermissionsStatus? status,
    List<PermissionItemEntity>? permissions,
    String? errorMessage,
    String? selectedRole,
  }) {
    return PermissionsState(
      status: status ?? this.status,
      permissions: permissions ?? this.permissions,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedRole: selectedRole ?? this.selectedRole,
    );
  }

  @override
  List<Object?> get props => [status, permissions, errorMessage, selectedRole];
}
