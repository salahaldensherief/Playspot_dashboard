import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/features/staff/data/models/staff_params.dart';
import 'package:play_spot_dashboard/features/staff/data/repos/staff_repos.dart';
import 'package:play_spot_dashboard/features/staff/presentation/staff_management/staff_state.dart';

class StaffCubit extends Cubit<StaffState> {
  final StaffRepository _repository;

  StaffCubit(this._repository) : super(StaffState.init());

  Future<void> fetchStaff(String loungeId) async {
    emit(state.copyWith(status: StaffStatus.loading));
    final result = await _repository.getLoungeStaff(loungeId);
    
    result.fold(
      (failure) => emit(state.copyWith(status: StaffStatus.failure, errorMessage: failure.message)),
      (staff) => emit(state.copyWith(status: StaffStatus.success, staffList: staff)),
    );
  }

  Future<void> addStaffMember(AddStaffParams params) async {
    emit(state.copyWith(status: StaffStatus.loading));
    final result = await _repository.addStaffMember(params);
    
    result.fold(
      (failure) => emit(state.copyWith(status: StaffStatus.failure, errorMessage: failure.message)),
      (updatedList) {
        emit(state.copyWith(
          status: StaffStatus.success,
          staffList: List.from(updatedList),
        ));
      },
    );
  }

  Future<void> toggleStaffStatus(String staffId, bool currentStatus, String loungeId) async {
    final result = await _repository.updateStaffStatus(staffId, !currentStatus);
    result.fold(
      (failure) => emit(state.copyWith(status: StaffStatus.failure, errorMessage: failure.message)),
      (_) => fetchStaff(loungeId),
    );
  }

  Future<void> deleteStaff(String staffId, String loungeId) async {
    final result = await _repository.deleteStaff(staffId);
    result.fold(
      (failure) => emit(state.copyWith(status: StaffStatus.failure, errorMessage: failure.message)),
      (_) => fetchStaff(loungeId),
    );
  }
}
