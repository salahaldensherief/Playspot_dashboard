import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/auth_repository.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _repository;

  LoginCubit(this._repository) : super(LoginState.init());

  Future<void> login(String email, String password) async {
    if (isClosed) return;
    emit(state.copyWith(status: LoginStatus.loading));
    final result = await _repository.login(email, password);
    if (isClosed) return;
    result.fold(
      (error) => emit(state.copyWith(status: LoginStatus.failure, errorMessage: error)),
      (admin) => emit(state.copyWith(status: LoginStatus.success, admin: admin)),
    );
  }
}
