import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user_entity.dart';

enum AdminManagementStatus { initial, loading, success, failure }

class AdminManagementState extends Equatable {
  final AdminManagementStatus status;
  final List<UserEntity> admins;
  final UserEntity? lastCreatedAdmin;
  final String? errorMessage;

  const AdminManagementState({
    this.status = AdminManagementStatus.initial,
    this.admins = const [],
    this.lastCreatedAdmin,
    this.errorMessage,
  });

  AdminManagementState copyWith({
    AdminManagementStatus? status,
    List<UserEntity>? admins,
    UserEntity? lastCreatedAdmin,
    String? errorMessage,
  }) {
    return AdminManagementState(
      status: status ?? this.status,
      admins: admins ?? this.admins,
      lastCreatedAdmin: lastCreatedAdmin ?? this.lastCreatedAdmin,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, admins, lastCreatedAdmin, errorMessage];
}
