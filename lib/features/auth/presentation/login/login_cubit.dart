import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/services/location_service.dart';
import '../../domain/usecases/login_params.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../../lounges/domain/repositories/lounge_repository.dart';
import '../../../../core/usecases/base_usecase.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final LoungeRepository loungeRepository;
  final LocationService locationService;

  LoginCubit({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.loungeRepository,
    required this.locationService,
  }) : super(const LoginState());

  Future<void> checkInitialAuth({BuildContext? context}) async {
    debugPrint('LoginCubit: checking initial auth');
    emit(state.copyWith(status: LoginStatus.checking));
    final result = await getCurrentUserUseCase(NoParams());
    result.fold(
      (failure) {
        debugPrint('LoginCubit: initial auth check failed: ${failure.message}');
        emit(state.copyWith(status: LoginStatus.unauthenticated));
      },
      (user) async {
        debugPrint('LoginCubit: user found: ${user?.email}, role: ${user?.role}');
        if (user != null) {
          emit(state.copyWith(
            status: LoginStatus.authenticated,
            user: user,
            isSetupCompleted: user.isSetupCompleted,
          ));
          
          if (user.isStaff && user.loungeId != null) {
            _handleLoungeAdminAuth(user, context: context);
          }
        } else {
          emit(state.copyWith(status: LoginStatus.unauthenticated));
        }
      },
    );
  }

  Future<void> login(String email, String password, { BuildContext? context}) async {
    debugPrint('LoginCubit: logging in for $email');
    emit(state.copyWith(status: LoginStatus.loading));
    final result = await loginUseCase(LoginParams(email: email, password: password));
    result.fold(
      (failure) {
        debugPrint('LoginCubit: login failed: ${failure.message}');
        emit(state.copyWith(status: LoginStatus.failure, errorMessage: failure.message));
      },
      (user) async {
        debugPrint('LoginCubit: login success for ${user.email}');
        emit(state.copyWith(
          status: LoginStatus.authenticated,
          user: user,
          isSetupCompleted: user.isSetupCompleted,
        ));

        if (user.isStaff && user.loungeId != null) {
          _handleLoungeAdminAuth(user, context: context);
        }
      },
    );
  }

  Future<void> _handleLoungeAdminAuth(UserEntity user, {BuildContext? context}) async {
    final loungeId = user.loungeId;
    if (loungeId == null) return;

    final loungeResult = await loungeRepository.getLoungeById(loungeId);
    loungeResult.fold(
      (_) => null,
      (lounge) async {
        emit(state.copyWith(userLounge: lounge));
        // We removed the location capture from here to avoid redundancy and potential loops.
        // It's now handled by the GeolocationHandler in the UI Shell.
      },
    );
  }

  /// Reloads profile to refresh isSetupCompleted status
  Future<void> refreshProfile() async {
    final result = await getCurrentUserUseCase(NoParams());
    result.fold(
      (_) => null,
      (user) {
        if (user != null) {
          emit(state.copyWith(
            user: user,
            isSetupCompleted: user.isSetupCompleted,
          ));
        }
      },
    );
  }

  void updateUser(UserEntity user) {
    emit(state.copyWith(user: user, isSetupCompleted: user.isSetupCompleted));
  }

  Future<void> logout() async {
    await logoutUseCase(NoParams());
    emit(const LoginState(status: LoginStatus.unauthenticated));
  }
}
