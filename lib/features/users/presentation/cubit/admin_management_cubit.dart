import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import '../../domain/usecases/create_lounge_admin_usecase.dart';
import '../../domain/usecases/delete_admin_usecase.dart';
import '../../domain/usecases/get_admins_usecase.dart';
import '../../domain/usecases/update_admin_usecase.dart';
import 'admin_management_state.dart';

class AdminManagementCubit extends Cubit<AdminManagementState> {
  final CreateLoungeAdminUseCase createLoungeAdminUseCase;
  final GetAdminsUseCase getAdminsUseCase;
  final DeleteAdminUseCase deleteAdminUseCase;
  final UpdateAdminUseCase updateAdminUseCase;

  AdminManagementCubit({
    required this.createLoungeAdminUseCase,
    required this.getAdminsUseCase,
    required this.deleteAdminUseCase,
    required this.updateAdminUseCase,
  }) : super(const AdminManagementState());

  Future<void> fetchAdmins() async {
    emit(state.copyWith(status: AdminManagementStatus.loading));
    final result = await getAdminsUseCase();

    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.error('Failed to fetch admins: ${failure.message}');
        emit(state.copyWith(
          status: AdminManagementStatus.failure,
          errorMessage: failure.message,
        ));
      },
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
      (failure) {
        AppLogger.error('Failed to create admin: ${failure.message}');
        emit(state.copyWith(
          status: AdminManagementStatus.failure,
          errorMessage: failure.message,
        ));
      },
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
    final result = await deleteAdminUseCase(adminId);

    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.error('Failed to delete admin: ${failure.message}');
        emit(state.copyWith(
          status: AdminManagementStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (_) {
        final updatedAdmins = state.admins.where((a) => a.id != adminId).toList();
        emit(state.copyWith(
          status: AdminManagementStatus.success,
          admins: updatedAdmins,
        ));
        fetchAdmins();
      },
    );
  }

  Future<void> updateAdmin(String adminId, {String? name, String? email}) async {
    emit(state.copyWith(status: AdminManagementStatus.loading));
    final result = await updateAdminUseCase(UpdateAdminParams(
      adminId: adminId,
      name: name,
      email: email,
    ));

    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.error('Failed to update admin: ${failure.message}');
        emit(state.copyWith(
          status: AdminManagementStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (_) => fetchAdmins(),
    );
  }
}
