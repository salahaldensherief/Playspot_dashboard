import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/extra_entity.dart';
import '../../domain/repositories/lounge_repository.dart';
import 'extras_state.dart';

class ExtrasCubit extends Cubit<ExtrasState> {
  final LoungeRepository repository;

  ExtrasCubit(this.repository) : super(const ExtrasState());

  Future<void> loadExtras(String loungeId, {bool forceRefresh = false}) async {
    emit(state.copyWith(status: ExtrasStatus.loading));
    final result = await repository.getExtras(loungeId, forceRefresh: forceRefresh);
    
    if (isClosed) return;

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
    
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: ExtrasStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => loadExtras(loungeId),
    );
  }

  Future<bool> addExtra(ExtraEntity extra) async {
    final result = await repository.addExtra(extra);
    
    if (isClosed) return false;

    return result.fold<Future<bool>>(
      (failure) async {
        emit(state.copyWith(
        status: ExtrasStatus.failure,
        errorMessage: failure.message,
        ));
        return false;
      },
      (_) async { await loadExtras(extra.loungeId); return true; },
    );
  }

  Future<bool> updateExtra(ExtraEntity extra) async {
    final result = await repository.updateExtra(extra);
    
    if (isClosed) return false;

    return result.fold<Future<bool>>(
      (failure) async {
        emit(state.copyWith(
        status: ExtrasStatus.failure,
        errorMessage: failure.message,
        ));
        return false;
      },
      (_) async { await loadExtras(extra.loungeId); return true; },
    );
  }

  Future<void> deleteExtra(String extraId, String loungeId) async {
    final result = await repository.deleteExtra(extraId);
    
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: ExtrasStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => loadExtras(loungeId),
    );
  }
}
