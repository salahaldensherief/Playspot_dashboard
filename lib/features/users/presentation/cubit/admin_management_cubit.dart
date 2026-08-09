import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_lounge_admin_usecase.dart';
import 'admin_management_state.dart';

class AdminManagementCubit extends Cubit<AdminManagementState> {
  final CreateLoungeAdminUseCase createLoungeAdminUseCase;

  AdminManagementCubit(this.createLoungeAdminUseCase) : super(AdminManagementInitial());

  Future<void> createLoungeAdmin({
    required String email,
    required String password,
    required String name,
  }) async {
    emit(AdminManagementLoading());
    final result = await createLoungeAdminUseCase(
      email: email,
      password: password,
      name: name,
    );
    
    result.fold(
      (failure) => emit(AdminManagementError(failure.message)),
      (admin) => emit(AdminManagementSuccess(admin)),
    );
  }
}
