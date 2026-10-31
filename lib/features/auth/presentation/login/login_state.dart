import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../../lounges/domain/entities/lounge.dart';

enum LoginStatus {
  initial,
  checking,
  profileFailure,
  loading,
  success,
  failure,
  authenticated,
  unauthenticated,
}

class LoginState extends Equatable {
  static const _unchanged = Object();
  final LoginStatus status;
  final UserEntity? user;
  final Lounge? userLounge;
  final bool isLoadingLounge;
  final String? loungeLoadError;
  final String? errorMessage;
  final bool isSetupCompleted;
  final bool locationCaptured;
  final bool isLoadingLocation;
  final String? locationErrorMessage;

  const LoginState({
    this.status = LoginStatus.initial,
    this.user,
    this.userLounge,
    this.isLoadingLounge = false,
    this.loungeLoadError,
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
    bool clearUserLounge = false,
    bool? isLoadingLounge,
    Object? loungeLoadError = _unchanged,
    Object? errorMessage = _unchanged,
    bool? isSetupCompleted,
    bool? locationCaptured,
    bool? isLoadingLocation,
    Object? locationErrorMessage = _unchanged,
  }) {
    return LoginState(
      status: status ?? this.status,
      user: user ?? this.user,
      userLounge: clearUserLounge ? null : userLounge ?? this.userLounge,
      isLoadingLounge: isLoadingLounge ?? this.isLoadingLounge,
      loungeLoadError: identical(loungeLoadError, _unchanged)
          ? this.loungeLoadError
          : loungeLoadError as String?,
      errorMessage: identical(errorMessage, _unchanged)
          ? this.errorMessage
          : errorMessage as String?,
      isSetupCompleted: isSetupCompleted ?? this.isSetupCompleted,
      locationCaptured: locationCaptured ?? this.locationCaptured,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      locationErrorMessage: identical(locationErrorMessage, _unchanged)
          ? this.locationErrorMessage
          : locationErrorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    userLounge,
    isLoadingLounge,
    loungeLoadError,
    errorMessage,
    isSetupCompleted,
    locationCaptured,
    isLoadingLocation,
    locationErrorMessage,
  ];
}
