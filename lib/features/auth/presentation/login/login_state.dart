import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_entity.dart';

enum LoginStatus { initial, loading, success, failure, authenticated }

class LoginState extends Equatable {
  final LoginStatus status;
  final AdminEntity? admin;
  final String? errorMessage;

  const LoginState({
    this.status = LoginStatus.initial,
    this.admin,
    this.errorMessage,
  });

  factory LoginState.init() => const LoginState();

  LoginState copyWith({
    LoginStatus? status,
    AdminEntity? admin,
    String? errorMessage,
  }) {
    return LoginState(
      status: status ?? this.status,
      admin: admin ?? this.admin,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, admin, errorMessage];

}
