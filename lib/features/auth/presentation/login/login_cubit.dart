import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../core/usecases/base_usecase.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  LoginCubit({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
  }) : super(const LoginState());

  Future<void> checkInitialAuth() async {
    final result = await getCurrentUserUseCase(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(status: LoginStatus.initial)),
      (user) {
        if (user != null) {
          emit(state.copyWith(
            status: LoginStatus.authenticated,
            user: user,
            isSetupCompleted: user.isSetupCompleted,
          ));
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
      (user) {
        emit(state.copyWith(
          status: LoginStatus.authenticated,
          user: user,
          isSetupCompleted: user.isSetupCompleted,
        ));
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
