import 'package:equatable/equatable.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';

abstract class AdminManagementState extends Equatable {
  const AdminManagementState();

  @override
  List<Object?> get props => [];
}

class AdminManagementInitial extends AdminManagementState {}

class AdminManagementLoading extends AdminManagementState {}

class AdminManagementLoaded extends AdminManagementState {
  final List<UserEntity> admins;
  const AdminManagementLoaded(this.admins);

  @override
  List<Object?> get props => [admins];
}

class AdminManagementSuccess extends AdminManagementState {
  final UserEntity admin;
  const AdminManagementSuccess(this.admin);

  @override
  List<Object?> get props => [admin];
}

class AdminManagementError extends AdminManagementState {
  final String message;
  const AdminManagementError(this.message);

  @override
  List<Object?> get props => [message];
}
