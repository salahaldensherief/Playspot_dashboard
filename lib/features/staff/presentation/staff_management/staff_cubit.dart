import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/art_core/app_strings.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/staff/data/models/staff_params.dart';
import 'package:play_spot_dashboard/features/staff/data/repos/staff_repos.dart';
import 'package:play_spot_dashboard/features/staff/presentation/staff_management/staff_state.dart';

class StaffCubit extends Cubit<StaffState> {
  final StaffRepository _repository;

  StaffCubit(this._repository) : super(StaffState.init());

  Future<void> fetchStaff(String loungeId) async {
    final cleanLoungeId = loungeId.trim();
    if (cleanLoungeId.isEmpty) {
      debugPrint('StaffCubit: fetchStaff skipped because loungeId is empty');
      return;
    }
    
    debugPrint('StaffCubit: fetchStaff started for loungeId: $cleanLoungeId');
    emit(state.copyWith(status: StaffStatus.loading));
    final result = await _repository.getLoungeStaff(cleanLoungeId);
    
    if (isClosed) return;

    result.fold(
      (failure) {
        debugPrint('StaffCubit: fetchStaff failed: ${failure.message}');
        emit(state.copyWith(status: StaffStatus.failure, errorMessage: failure.message));
      },
      (staff) {
        debugPrint('StaffCubit: fetchStaff success, found ${staff.length} staff members');
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

    debugPrint('StaffCubit: addStaffMember started for ${params.email}');
    emit(state.copyWith(status: StaffStatus.loading));
    final result = await _repository.addStaffMember(params);
    
    if (isClosed) return;

    result.fold(
      (failure) {
        debugPrint('StaffCubit: addStaffMember failed: ${failure.message}');
        emit(state.copyWith(status: StaffStatus.failure, errorMessage: failure.message));
      },
      (_) {
        debugPrint('StaffCubit: addStaffMember success, refetching staff list');
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
    final result = await _repository.updateStaffMember(staffId, data);
    
    if (isClosed) return;

    result.fold(
      (failure) {
        debugPrint('🔴 [STAFF_CUBIT] updateStaffMember failed: ${failure.message}');
        emit(state.copyWith(status: StaffStatus.failure, errorMessage: failure.message));
      },
      (_) async {
        debugPrint('🟢 [STAFF_CUBIT] updateStaffMember success, refreshing staff list');
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

    final result = await _repository.updateStaffStatus(staffId, !currentStatus);
    if (isClosed) return;

    result.fold(
      (failure) {
        debugPrint('🔴 [STAFF_CUBIT] toggleStaffStatus failed: ${failure.message}');
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

    final result = await _repository.deleteStaff(staffId);
    if (isClosed) return;

    result.fold(
      (failure) {
        debugPrint('🔴 [STAFF_CUBIT] deleteStaff failed: ${failure.message}');
        emit(state.copyWith(status: StaffStatus.failure, errorMessage: failure.message));
        fetchStaff(loungeId);
      },
      (_) => fetchStaff(loungeId),
    );
  }
}
