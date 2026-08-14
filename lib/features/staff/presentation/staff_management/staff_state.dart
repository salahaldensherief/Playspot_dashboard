import 'package:equatable/equatable.dart';
import 'package:play_spot_dashboard/features/staff/data/entities/staff_entity.dart';

enum StaffStatus {
  initial,
  loading,
  success,
  failure;

  bool get isInitial => this == StaffStatus.initial;
  bool get isLoading => this == StaffStatus.loading;
  bool get isSuccess => this == StaffStatus.success;
  bool get isFailure => this == StaffStatus.failure;
}

class StaffState extends Equatable {
  final StaffStatus status;
  final List<StaffEntity> staffList;
  final String? errorMessage;

  const StaffState({
    required this.status,
    this.staffList = const [],
    this.errorMessage,
  });

  factory StaffState.init() {
    return const StaffState(
      status: StaffStatus.initial,
      staffList: [],
    );
  }

  StaffState copyWith({
    StaffStatus? status,
    List<StaffEntity>? staffList,
    String? errorMessage,
  }) {
    return StaffState(
      status: status ?? this.status,
      staffList: staffList ?? this.staffList,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, staffList, errorMessage];
}
