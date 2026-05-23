import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  AuthCubit(this._repository) : super(AuthState.initial());

  Future<void> checkAuth() async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _repository.getCurrentUser();
    result.fold(
      (error) => emit(state.copyWith(status: AuthStatus.unauthenticated, errorMessage: error)),
      (admin) {
        if (admin != null) {
          emit(state.copyWith(status: AuthStatus.authenticated, admin: admin));
        } else {
          emit(state.copyWith(status: AuthStatus.unauthenticated));
        }
      },
    );
  }

  Future<void> login(String email, String password) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _repository.login(email, password);
    result.fold(
      (error) => emit(state.copyWith(status: AuthStatus.failure, errorMessage: error)),
      (admin) => emit(state.copyWith(status: AuthStatus.authenticated, admin: admin)),
    );
  }

  Future<void> logout() async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await _repository.logout();
    result.fold(
      (error) => emit(state.copyWith(status: AuthStatus.failure, errorMessage: error)),
      (_) => emit(AuthState.initial().copyWith(status: AuthStatus.unauthenticated)),
    );
  }
}
