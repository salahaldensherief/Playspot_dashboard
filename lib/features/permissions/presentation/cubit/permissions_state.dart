import 'package:equatable/equatable.dart';
import '../../domain/entities/permission_item_entity.dart';

enum PermissionsStatus { initial, loading, success, failure }

class PermissionsState extends Equatable {
  final PermissionsStatus status;
  final PermissionsStatus accessStatus;
  final List<PermissionItemEntity> permissions;
  final Map<String, bool> userPermissions;
  final int page;
  final int pageSize;
  final int totalCount;
  final String? errorMessage;
  final String selectedRole;
  final String? userRole;
  final String? userId;

  const PermissionsState({
    required this.status,
    this.accessStatus = PermissionsStatus.initial,
    this.permissions = const [],
    this.userPermissions = const {},
    this.page = 1,
    this.pageSize = 50,
    this.totalCount = 0,
    this.errorMessage,
    this.selectedRole = 'cashier',
    this.userRole,
    this.userId,
  });

  factory PermissionsState.initial() =>
      const PermissionsState(status: PermissionsStatus.initial);

  bool get hasNextPage => page * pageSize < totalCount;
  bool get hasPreviousPage => page > 1;
  int get totalPages => pageSize > 0 ? (totalCount / pageSize).ceil() : 0;

  PermissionsState copyWith({
    PermissionsStatus? status,
    PermissionsStatus? accessStatus,
    List<PermissionItemEntity>? permissions,
    Map<String, bool>? userPermissions,
    int? page,
    int? pageSize,
    int? totalCount,
    String? errorMessage,
    String? selectedRole,
    String? userRole,
    String? userId,
  }) {
    return PermissionsState(
      status: status ?? this.status,
      accessStatus: accessStatus ?? this.accessStatus,
      permissions: permissions ?? this.permissions,
      userPermissions: userPermissions ?? this.userPermissions,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedRole: selectedRole ?? this.selectedRole,
      userRole: userRole ?? this.userRole,
      userId: userId ?? this.userId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    accessStatus,
    permissions,
    userPermissions,
    page,
    pageSize,
    totalCount,
    errorMessage,
    selectedRole,
    userRole,
    userId,
  ];
}
