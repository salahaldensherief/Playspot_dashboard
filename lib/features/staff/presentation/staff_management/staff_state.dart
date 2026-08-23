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
  final String searchQuery;
  final String? errorMessage;

  const StaffState({
    required this.status,
    this.staffList = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  factory StaffState.init() {
    return const StaffState(
      status: StaffStatus.initial,
      staffList: [],
      searchQuery: '',
    );
  }

  List<StaffEntity> get filteredStaff {
    if (searchQuery.isEmpty) return staffList;
    return staffList.where((staff) {
      return staff.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
             staff.email.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  StaffState copyWith({
    StaffStatus? status,
    List<StaffEntity>? staffList,
    String? searchQuery,
    String? errorMessage,
  }) {
    return StaffState(
      status: status ?? this.status,
      staffList: staffList ?? this.staffList,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, staffList, searchQuery, errorMessage];
}
