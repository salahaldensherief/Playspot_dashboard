import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_lounge_admin_usecase.dart';
import '../../domain/usecases/get_admins_usecase.dart';
import 'admin_management_state.dart';

class AdminManagementCubit extends Cubit<AdminManagementState> {
  final CreateLoungeAdminUseCase createLoungeAdminUseCase;
  final GetAdminsUseCase getAdminsUseCase;

  AdminManagementCubit({
    required this.createLoungeAdminUseCase,
    required this.getAdminsUseCase,
  }) : super(AdminManagementInitial());

  Future<void> fetchAdmins() async {
    emit(AdminManagementLoading());
    final result = await getAdminsUseCase();
    result.fold(
      (failure) => emit(AdminManagementError(failure.message)),
      (admins) => emit(AdminManagementLoaded(admins)),
    );
  }

  Future<void> createLoungeAdmin({
    required String email,
    required String password,
    required String name,
    required String loungeName,
    String? city,
  }) async {
    emit(AdminManagementLoading());
    final result = await createLoungeAdminUseCase(
      email: email,
      password: password,
      name: name,
      loungeName: loungeName,
      city: city,
    );
    
    result.fold(
      (failure) => emit(AdminManagementError(failure.message)),
      (admin) {
        emit(AdminManagementSuccess(admin));
        fetchAdmins();
      },
    );
  }
}
