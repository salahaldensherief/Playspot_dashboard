import 'package:equatable/equatable.dart';
import '../../domain/entities/shift_entity.dart';
import '../../domain/entities/live_shift_overview_entity.dart';

enum ShiftStatus { 
  initial, 
  loading, 
  active, 
  closed, 
  error;

  bool get isInitial => this == ShiftStatus.initial;
  bool get isLoading => this == ShiftStatus.loading;
  bool get isActive => this == ShiftStatus.active;
  bool get isClosed => this == ShiftStatus.closed;
  bool get isError => this == ShiftStatus.error;
}

class ShiftState extends Equatable {
  final ShiftStatus status;
  final ShiftEntity? activeShift;
  final LiveShiftOverviewEntity? liveOverview;
  final ShiftEntity? lastClosedShift;
  final String? errorMessage;
  final List<ShiftEntity> shifts;

  const ShiftState({
    required this.status,
    this.activeShift,
    this.liveOverview,
    this.lastClosedShift,
    this.errorMessage,
    this.shifts = const [],
  });

  factory ShiftState.initial() => const ShiftState(status: ShiftStatus.initial);

  ShiftState copyWith({
    ShiftStatus? status,
    ShiftEntity? activeShift,
    LiveShiftOverviewEntity? liveOverview,
    ShiftEntity? lastClosedShift,
    String? errorMessage,
    List<ShiftEntity>? shifts,
  }) {
    return ShiftState(
      status: status ?? this.status,
      activeShift: activeShift ?? (status == ShiftStatus.closed ? null : this.activeShift),
      liveOverview: liveOverview ?? this.liveOverview,
      lastClosedShift: lastClosedShift ?? this.lastClosedShift,
      errorMessage: errorMessage ?? this.errorMessage,
      shifts: shifts ?? this.shifts,
    );
  }

  @override
  List<Object?> get props => [status, activeShift, liveOverview, lastClosedShift, errorMessage, shifts];
}
