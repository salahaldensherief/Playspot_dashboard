import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_lounge_admin_usecase.dart';
import '../../domain/usecases/get_admins_usecase.dart';
import '../../domain/repositories/admin_management_repository.dart';
import 'admin_management_state.dart';

class AdminManagementCubit extends Cubit<AdminManagementState> {
  final CreateLoungeAdminUseCase createLoungeAdminUseCase;
  final GetAdminsUseCase getAdminsUseCase;
  final AdminManagementRepository repository;

  AdminManagementCubit({
    required this.createLoungeAdminUseCase,
    required this.getAdminsUseCase,
    required this.repository,
  }) : super(const AdminManagementState());

  Future<void> fetchAdmins() async {
    emit(state.copyWith(status: AdminManagementStatus.loading));
    final result = await getAdminsUseCase();
    
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: AdminManagementStatus.failure,
        errorMessage: failure.message,
      )),
      (admins) => emit(state.copyWith(
        status: AdminManagementStatus.success,
        admins: admins,
      )),
    );
  }

  Future<void> createLoungeAdmin({
    required String email,
    required String password,
    required String name,
    required String loungeName,
    String? city,
  }) async {
    emit(state.copyWith(status: AdminManagementStatus.loading));
    final result = await createLoungeAdminUseCase(
      email: email,
      password: password,
      name: name,
      loungeName: loungeName,
      city: city,
    );
    
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: AdminManagementStatus.failure,
        errorMessage: failure.message,
      )),
      (admin) {
        emit(state.copyWith(
          status: AdminManagementStatus.success,
          lastCreatedAdmin: admin,
        ));
        fetchAdmins();
      },
    );
  }

  Future<void> deleteAdmin(String adminId) async {
    emit(state.copyWith(status: AdminManagementStatus.loading));
    final result = await repository.deleteAdmin(adminId);
    
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: AdminManagementStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => fetchAdmins(),
    );
  }
}
