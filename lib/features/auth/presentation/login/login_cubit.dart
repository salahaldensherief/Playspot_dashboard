import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/admin_entity.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _repository;

  LoginCubit(this._repository) : super(const LoginState());

  Future<void> checkInitialAuth() async {
    final result = await _repository.getCurrentUser();
    result.fold(
      (error) => emit(state.copyWith(status: LoginStatus.initial)),
      (admin) {
        if (admin != null) {
          emit(state.copyWith(status: LoginStatus.authenticated, admin: admin));
        } else {
          emit(state.copyWith(status: LoginStatus.initial));
        }
      },
    );
  }

  Future<void> login(String email, String password) async {
    emit(state.copyWith(status: LoginStatus.loading));
    final result = await _repository.login(email, password);
    result.fold(
      (error) => emit(state.copyWith(status: LoginStatus.failure, errorMessage: error)),
      (admin) => emit(state.copyWith(status: LoginStatus.authenticated, admin: admin)),
    );
  }

  void updateAdmin(AdminEntity admin) {
    emit(state.copyWith(admin: admin));
  }

  Future<void> logout() async {
    await _repository.logout();
    emit(const LoginState());
  }
}
