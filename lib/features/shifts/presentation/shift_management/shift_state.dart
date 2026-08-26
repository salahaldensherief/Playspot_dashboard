import 'package:equatable/equatable.dart';
import '../../domain/entities/shift_entity.dart';

enum ShiftStatus {
  initial,
  loading,
  success,
  active,
  noActive,
  closed,
  failure;

  bool get isInitial => this == ShiftStatus.initial;
  bool get isLoading => this == ShiftStatus.loading;
  bool get isSuccess => this == ShiftStatus.success;
  bool get isActive => this == ShiftStatus.active;
  bool get isNoActive => this == ShiftStatus.noActive;
  bool get isClosed => this == ShiftStatus.closed;
  bool get isFailure => this == ShiftStatus.failure;
}

class ShiftState extends Equatable {
  final ShiftStatus status;
  final ShiftEntity? activeShift;
  final List<ShiftEntity> shifts;
  final String? errorMessage;
  final ShiftEntity? closedShiftReport; // For Z-Report preview

  const ShiftState({
    required this.status,
    this.activeShift,
    this.shifts = const [],
    this.errorMessage,
    this.closedShiftReport,
  });

  factory ShiftState.init() {
    return const ShiftState(
      status: ShiftStatus.initial,
      shifts: [],
    );
  }

  ShiftState copyWith({
    ShiftStatus? status,
    ShiftEntity? activeShift,
    List<ShiftEntity>? shifts,
    String? errorMessage,
    ShiftEntity? closedShiftReport,
  }) {
    return ShiftState(
      status: status ?? this.status,
      activeShift: activeShift ?? this.activeShift,
      shifts: shifts ?? this.shifts,
      errorMessage: errorMessage ?? this.errorMessage,
      closedShiftReport: closedShiftReport ?? this.closedShiftReport,
    );
  }

  @override
  List<Object?> get props => [status, activeShift, shifts, errorMessage, closedShiftReport];
}
