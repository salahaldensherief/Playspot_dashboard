import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../../lounges/domain/entities/lounge.dart';

enum LoginStatus { initial, loading, success, failure, authenticated }

class LoginState extends Equatable {
  final LoginStatus status;
  final UserEntity? user;
  final Lounge? userLounge;
  final String? errorMessage;
  final bool isSetupCompleted;

  const LoginState({
    this.status = LoginStatus.initial,
    this.user,
    this.userLounge,
    this.errorMessage,
    this.isSetupCompleted = false,
  });

  factory LoginState.init() => const LoginState();

  LoginState copyWith({
    LoginStatus? status,
    UserEntity? user,
    Lounge? userLounge,
    String? errorMessage,
    bool? isSetupCompleted,
  }) {
    return LoginState(
      status: status ?? this.status,
      user: user ?? this.user,
      userLounge: userLounge ?? this.userLounge,
      errorMessage: errorMessage ?? this.errorMessage,
      isSetupCompleted: isSetupCompleted ?? this.isSetupCompleted,
    );
  }

  @override
  List<Object?> get props => [status, user, userLounge, errorMessage, isSetupCompleted];
}
