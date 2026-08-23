import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/features/staff/data/models/staff_params.dart';
import 'package:play_spot_dashboard/features/staff/data/repos/staff_repos.dart';
import 'package:play_spot_dashboard/features/staff/presentation/staff_management/staff_state.dart';

class StaffCubit extends Cubit<StaffState> {
  final StaffRepository _repository;

  StaffCubit(this._repository) : super(StaffState.init());

  Future<void> fetchStaff(String loungeId) async {
    if (loungeId.isEmpty) {
      debugPrint('StaffCubit: fetchStaff skipped because loungeId is empty');
      return;
    }
    
    debugPrint('StaffCubit: fetchStaff started for loungeId: $loungeId');
    emit(state.copyWith(status: StaffStatus.loading));
    final result = await _repository.getLoungeStaff(loungeId);
    
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

  Future<void> addStaffMember(AddStaffParams params) async {
    debugPrint('StaffCubit: addStaffMember started for ${params.email}');
    emit(state.copyWith(status: StaffStatus.loading));
    final result = await _repository.addStaffMember(params);
    
    result.fold(
      (failure) {
        debugPrint('StaffCubit: addStaffMember failed: ${failure.message}');
        emit(state.copyWith(status: StaffStatus.failure, errorMessage: failure.message));
      },
      (updatedList) {
        debugPrint('StaffCubit: addStaffMember success, updated list length: ${updatedList.length}');
        emit(state.copyWith(
          status: StaffStatus.success,
          staffList: List.from(updatedList),
        ));
      },
    );
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  Future<void> updateStaffMember(String staffId, Map<String, dynamic> data, String loungeId) async {
    emit(state.copyWith(status: StaffStatus.loading));
    final result = await _repository.updateStaffMember(staffId, data);
    
    result.fold(
      (failure) => emit(state.copyWith(status: StaffStatus.failure, errorMessage: failure.message)),
      (_) => fetchStaff(loungeId),
    );
  }

  Future<void> toggleStaffStatus(String staffId, bool currentStatus, String loungeId) async {
    // Optimistic update for immediate UI rebuild
    final updatedList = state.staffList.map((staff) {
      if (staff.id == staffId) {
        return staff.copyWith(isActive: !currentStatus);
      }
      return staff;
    }).toList();
    emit(state.copyWith(staffList: updatedList));

    final result = await _repository.updateStaffStatus(staffId, !currentStatus);
    result.fold(
      (failure) {
        // Rollback on failure
        emit(state.copyWith(status: StaffStatus.failure, errorMessage: failure.message));
        fetchStaff(loungeId);
      },
      (_) => null, // Success, already updated locally
    );
  }

  Future<void> deleteStaff(String staffId, String loungeId) async {
    // Optimistic update
    final updatedList = state.staffList.where((staff) => staff.id != staffId).toList();
    emit(state.copyWith(staffList: updatedList));

    final result = await _repository.deleteStaff(staffId);
    result.fold(
      (failure) {
        // Rollback on failure
        emit(state.copyWith(status: StaffStatus.failure, errorMessage: failure.message));
        fetchStaff(loungeId);
      },
      (_) => null, // Success
    );
  }
}
