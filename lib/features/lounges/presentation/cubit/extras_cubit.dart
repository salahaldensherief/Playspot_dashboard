import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/extra_entity.dart';
import '../../domain/repositories/lounge_repository.dart';

abstract class ExtrasState extends Equatable {
  const ExtrasState();
  @override
  List<Object?> get props => [];
}

class ExtrasInitial extends ExtrasState {}
class ExtrasLoading extends ExtrasState {}
class ExtrasLoaded extends ExtrasState {
  final List<ExtraEntity> extras;
  const ExtrasLoaded(this.extras);
  @override
  List<Object?> get props => [extras];
}
class ExtrasError extends ExtrasState {
  final String message;
  const ExtrasError(this.message);
  @override
  List<Object?> get props => [message];
}

class ExtrasCubit extends Cubit<ExtrasState> {
  final LoungeRepository repository;

  ExtrasCubit(this.repository) : super(ExtrasInitial());

  Future<void> loadExtras(String loungeId) async {
    emit(ExtrasLoading());
    final result = await repository.getExtras(loungeId);
    result.fold(
      (failure) => emit(ExtrasError(failure.message)),
      (extras) => emit(ExtrasLoaded(extras)),
    );
  }

  Future<void> toggleStock(String extraId, bool isOutOfStock, String loungeId) async {
    final result = await repository.toggleExtraStock(extraId, isOutOfStock);
    result.fold(
      (failure) => emit(ExtrasError(failure.message)),
      (_) => loadExtras(loungeId),
    );
  }

  Future<void> addExtra(ExtraEntity extra) async {
    final result = await repository.addExtra(extra);
    result.fold(
      (failure) => emit(ExtrasError(failure.message)),
      (_) => loadExtras(extra.loungeId),
    );
  }
}
