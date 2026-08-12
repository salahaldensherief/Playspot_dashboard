import 'package:equatable/equatable.dart';
import '../../domain/entities/extra_entity.dart';

enum ExtrasStatus { initial, loading, success, failure }

class ExtrasState extends Equatable {
  final ExtrasStatus status;
  final List<ExtraEntity> extras;
  final String? errorMessage;

  const ExtrasState({
    this.status = ExtrasStatus.initial,
    this.extras = const [],
    this.errorMessage,
  });

  ExtrasState copyWith({
    ExtrasStatus? status,
    List<ExtraEntity>? extras,
    String? errorMessage,
  }) {
    return ExtrasState(
      status: status ?? this.status,
      extras: extras ?? this.extras,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, extras, errorMessage];
}
