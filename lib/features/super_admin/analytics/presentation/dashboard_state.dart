import 'package:equatable/equatable.dart';

enum FeatureStatus { initial, loading, success, failure;
  bool get isInitial => this == FeatureStatus.initial;
  bool get isLoading => this == FeatureStatus.loading;
  bool get isSuccess => this == FeatureStatus.success;
  bool get isFailure => this == FeatureStatus.failure;
}

class DashboardState extends Equatable {
  final FeatureStatus status;
  final String? errorMessage;

  const DashboardState({
    this.status = FeatureStatus.initial,
    this.errorMessage,
  });

  factory DashboardState.init() => const DashboardState();

  DashboardState copyWith({
    FeatureStatus? status,
    String? errorMessage,
  }) => DashboardState(
    status: status ?? this.status,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [status, errorMessage];
}
