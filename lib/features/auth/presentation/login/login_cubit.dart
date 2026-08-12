import 'package:flutter_bloc/flutter_bloc.dart';
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

  LoginCubit({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.loungeRepository,
  }) : super(const LoginState());

  Future<void> checkInitialAuth() async {
    final result = await getCurrentUserUseCase(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(status: LoginStatus.initial)),
      (user) async {
        if (user != null) {
          // If setup is not completed, we stay in authenticated but with isSetupCompleted = false
          // The router will handle the redirection to onboarding
          emit(state.copyWith(
            status: LoginStatus.authenticated,
            user: user,
            isSetupCompleted: user.isSetupCompleted,
          ));
          
          if (user.role == UserRole.loungeAdmin && user.loungeId != null) {
            final loungeResult = await loungeRepository.getLoungeById(user.loungeId!);
            loungeResult.fold(
              (_) => null,
              (lounge) => emit(state.copyWith(userLounge: lounge)),
            );
          }
        } else {
          emit(state.copyWith(status: LoginStatus.initial));
        }
      },
    );
  }

  Future<void> login(String email, String password) async {
    emit(state.copyWith(status: LoginStatus.loading));
    final result = await loginUseCase(LoginParams(email: email, password: password));
    result.fold(
      (failure) => emit(state.copyWith(status: LoginStatus.failure, errorMessage: failure.message)),
      (user) async {
        emit(state.copyWith(
          status: LoginStatus.authenticated,
          user: user,
          isSetupCompleted: user.isSetupCompleted,
        ));

        if (user.role == UserRole.loungeAdmin && user.loungeId != null) {
          final loungeResult = await loungeRepository.getLoungeById(user.loungeId!);
          loungeResult.fold(
            (_) => null,
            (lounge) => emit(state.copyWith(userLounge: lounge)),
          );
        }
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
    emit(const LoginState());
  }
}
