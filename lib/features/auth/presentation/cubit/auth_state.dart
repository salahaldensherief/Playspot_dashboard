import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_entity.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  final AuthStatus status;
  final AdminEntity? admin;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.admin,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    AdminEntity? admin,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      admin: admin ?? this.admin,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, admin, errorMessage];
}
