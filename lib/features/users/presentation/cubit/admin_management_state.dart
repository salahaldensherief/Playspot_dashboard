import 'package:equatable/equatable.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/admin_entity.dart';

abstract class AdminManagementState extends Equatable {
  const AdminManagementState();

  @override
  List<Object?> get props => [];
}

class AdminManagementInitial extends AdminManagementState {}

class AdminManagementLoading extends AdminManagementState {}

class AdminManagementSuccess extends AdminManagementState {
  final AdminEntity admin;
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
