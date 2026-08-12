import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/extra_entity.dart';
import '../../domain/repositories/lounge_repository.dart';
import 'extras_state.dart';

class ExtrasCubit extends Cubit<ExtrasState> {
  final LoungeRepository repository;

  ExtrasCubit(this.repository) : super(const ExtrasState());

  Future<void> loadExtras(String loungeId) async {
    emit(state.copyWith(status: ExtrasStatus.loading));
    final result = await repository.getExtras(loungeId);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ExtrasStatus.failure,
        errorMessage: failure.message,
      )),
      (extras) => emit(state.copyWith(
        status: ExtrasStatus.success,
        extras: extras,
      )),
    );
  }

  Future<void> toggleStock(String extraId, bool isOutOfStock, String loungeId) async {
    final result = await repository.toggleExtraStock(extraId, isOutOfStock);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ExtrasStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => loadExtras(loungeId),
    );
  }

  Future<void> addExtra(ExtraEntity extra) async {
    final result = await repository.addExtra(extra);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ExtrasStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => loadExtras(extra.loungeId),
    );
  }

  Future<void> updateExtra(ExtraEntity extra) async {
    final result = await repository.updateExtra(extra);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ExtrasStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => loadExtras(extra.loungeId),
    );
  }

  Future<void> deleteExtra(String extraId, String loungeId) async {
    final result = await repository.deleteExtra(extraId);
    result.fold(
      (failure) => emit(state.copyWith(
        status: ExtrasStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => loadExtras(loungeId),
    );
  }
}
