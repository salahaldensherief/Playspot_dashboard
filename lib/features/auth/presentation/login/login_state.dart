import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../../lounges/domain/entities/lounge.dart';

enum LoginStatus { initial, checking, loading, success, failure, authenticated, unauthenticated }

class LoginState extends Equatable {
  final LoginStatus status;
  final UserEntity? user;
  final Lounge? userLounge;
  final String? errorMessage;
  final bool isSetupCompleted;
  final bool locationCaptured;
  final bool isLoadingLocation;
  final String? locationErrorMessage;

  const LoginState({
    this.status = LoginStatus.initial,
    this.user,
    this.userLounge,
    this.errorMessage,
    this.isSetupCompleted = false,
    this.locationCaptured = false,
    this.isLoadingLocation = false,
    this.locationErrorMessage,
  });

  factory LoginState.init() => const LoginState();

  LoginState copyWith({
    LoginStatus? status,
    UserEntity? user,
    Lounge? userLounge,
    String? errorMessage,
    bool? isSetupCompleted,
    bool? locationCaptured,
    bool? isLoadingLocation,
    String? locationErrorMessage,
  }) {
    return LoginState(
      status: status ?? this.status,
      user: user ?? this.user,
      userLounge: userLounge ?? this.userLounge,
      errorMessage: errorMessage ?? this.errorMessage,
      isSetupCompleted: isSetupCompleted ?? this.isSetupCompleted,
      locationCaptured: locationCaptured ?? this.locationCaptured,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      locationErrorMessage: locationErrorMessage ?? this.locationErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        userLounge,
        errorMessage,
        isSetupCompleted,
        locationCaptured,
        isLoadingLocation,
        locationErrorMessage,
      ];
}
