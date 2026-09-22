import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/staff/data/models/staff_params.dart';
import 'package:play_spot_dashboard/features/staff/domain/usecases/add_staff_member_usecase.dart';
import 'package:play_spot_dashboard/features/staff/domain/usecases/delete_staff_usecase.dart';
import 'package:play_spot_dashboard/features/staff/domain/usecases/get_lounge_staff_usecase.dart';
import 'package:play_spot_dashboard/features/staff/domain/usecases/update_staff_member_usecase.dart';
import 'package:play_spot_dashboard/features/staff/domain/usecases/update_staff_status_usecase.dart';
import 'package:play_spot_dashboard/features/staff/presentation/staff_management/staff_state.dart';

class StaffCubit extends Cubit<StaffState> {
  final GetLoungeStaffUseCase _getLoungeStaffUseCase;
  final AddStaffMemberUseCase _addStaffMemberUseCase;
  final UpdateStaffMemberUseCase _updateStaffMemberUseCase;
  final UpdateStaffStatusUseCase _updateStaffStatusUseCase;
  final DeleteStaffUseCase _deleteStaffUseCase;

  StaffCubit({
    required GetLoungeStaffUseCase getLoungeStaffUseCase,
    required AddStaffMemberUseCase addStaffMemberUseCase,
    required UpdateStaffMemberUseCase updateStaffMemberUseCase,
    required UpdateStaffStatusUseCase updateStaffStatusUseCase,
    required DeleteStaffUseCase deleteStaffUseCase,
  })  : _getLoungeStaffUseCase = getLoungeStaffUseCase,
        _addStaffMemberUseCase = addStaffMemberUseCase,
        _updateStaffMemberUseCase = updateStaffMemberUseCase,
        _updateStaffStatusUseCase = updateStaffStatusUseCase,
        _deleteStaffUseCase = deleteStaffUseCase,
        super(StaffState.init());

  Future<void> fetchStaff(String loungeId) async {
    final cleanLoungeId = loungeId.trim();
    if (cleanLoungeId.isEmpty) {
      AppLogger.debug('StaffCubit: fetchStaff skipped because loungeId is empty');
      return;
    }
    
    AppLogger.debug('StaffCubit: fetchStaff started for loungeId: $cleanLoungeId');
    emit(state.copyWith(status: StaffStatus.loading));
    final result = await _getLoungeStaffUseCase(cleanLoungeId);
    
    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.warning('StaffCubit: fetchStaff failed: ${failure.message}');
        emit(state.copyWith(status: StaffStatus.failure, errorMessage: failure.message));
      },
      (staff) {
        AppLogger.info('StaffCubit: fetchStaff success, found ${staff.length} staff members');
        emit(state.copyWith(status: StaffStatus.success, staffList: staff));
      },
    );
  }

  Future<void> addStaffMember(AddStaffParams params, {UserEntity? currentUser}) async {
    if (currentUser != null && !currentUser.canManageStaff && !currentUser.isSuperAdmin) {
      emit(state.copyWith(
        status: StaffStatus.failure,
        errorMessage: AppStrings.managerOverrideRequired,
      ));
      return;
    }

    AppLogger.debug('StaffCubit: addStaffMember started for ${params.email}');
    emit(state.copyWith(status: StaffStatus.loading));
    final result = await _addStaffMemberUseCase(params);
    
    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.warning('StaffCubit: addStaffMember failed: ${failure.message}');
        emit(state.copyWith(status: StaffStatus.failure, errorMessage: failure.message));
      },
      (_) {
        AppLogger.info('StaffCubit: addStaffMember success, refetching staff list');
        fetchStaff(params.loungeId);
      },
    );
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  Future<void> updateStaffMember(
    String staffId,
    Map<String, dynamic> data,
    String loungeId, {
    UserEntity? currentUser,
  }) async {
    if (currentUser != null && !currentUser.canManageStaff && !currentUser.isSuperAdmin) {
      emit(state.copyWith(
        status: StaffStatus.failure,
        errorMessage: AppStrings.managerOverrideRequired,
      ));
      return;
    }

    emit(state.copyWith(status: StaffStatus.loading));
    final result = await _updateStaffMemberUseCase(
      UpdateStaffParams(staffId: staffId, data: data),
    );
    
    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.warning('StaffCubit: updateStaffMember failed: ${failure.message}');
        emit(state.copyWith(status: StaffStatus.failure, errorMessage: failure.message));
      },
      (_) async {
        AppLogger.info('StaffCubit: updateStaffMember success, refreshing staff list');
        await fetchStaff(loungeId);
      },
    );
  }

  Future<void> toggleStaffStatus(
    String staffId,
    bool currentStatus,
    String loungeId, {
    UserEntity? currentUser,
  }) async {
    if (currentUser != null && !currentUser.canManageStaff && !currentUser.isSuperAdmin) {
      emit(state.copyWith(
        status: StaffStatus.failure,
        errorMessage: AppStrings.managerOverrideRequired,
      ));
      return;
    }

    final updatedList = state.staffList.map((staff) {
      if (staff.id == staffId) {
        return staff.copyWith(isActive: !currentStatus);
      }
      return staff;
    }).toList();
    emit(state.copyWith(staffList: updatedList));

    final result = await _updateStaffStatusUseCase(
      UpdateStaffStatusParams(staffId: staffId, isActive: !currentStatus),
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.warning('StaffCubit: toggleStaffStatus failed: ${failure.message}');
        emit(state.copyWith(status: StaffStatus.failure, errorMessage: failure.message));
        fetchStaff(loungeId);
      },
      (_) => fetchStaff(loungeId),
    );
  }

  Future<void> deleteStaff(
    String staffId,
    String loungeId, {
    UserEntity? currentUser,
  }) async {
    if (currentUser != null && !currentUser.canManageStaff && !currentUser.isSuperAdmin) {
      emit(state.copyWith(
        status: StaffStatus.failure,
        errorMessage: AppStrings.managerOverrideRequired,
      ));
      return;
    }

    final updatedList = state.staffList.where((staff) => staff.id != staffId).toList();
    emit(state.copyWith(staffList: updatedList));

    final result = await _deleteStaffUseCase(staffId);
    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.warning('StaffCubit: deleteStaff failed: ${failure.message}');
        emit(state.copyWith(status: StaffStatus.failure, errorMessage: failure.message));
        fetchStaff(loungeId);
      },
      (_) => fetchStaff(loungeId),
    );
  }
}
