import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/usecases/get_lounge_owner_stats_usecase.dart';
import 'lounge_stats_state.dart';

class LoungeStatsCubit extends Cubit<LoungeStatsState> {
  final GetLoungeOwnerStatsUseCase getLoungeOwnerStatsUseCase;
  String? _loungeId;
  int _requestGeneration = 0;

  LoungeStatsCubit(this.getLoungeOwnerStatsUseCase)
    : super(const LoungeStatsState());

  Future<void> fetchStats(String? loungeId) async {
    if (isClosed) return;
    final cleanLoungeId = loungeId?.trim();
    final nextLoungeId = cleanLoungeId == null || cleanLoungeId.isEmpty
        ? null
        : cleanLoungeId;
    final scopeChanged = _loungeId != nextLoungeId;
    final generation = ++_requestGeneration;
    _loungeId = nextLoungeId;

    if (nextLoungeId == null) {
      emit(const LoungeStatsState());
      return;
    }

    emit(
      scopeChanged
          ? const LoungeStatsState(status: LoungeStatsStatus.loading)
          : state.copyWith(status: LoungeStatsStatus.loading),
    );

    final result = await getLoungeOwnerStatsUseCase(nextLoungeId);

    if (isClosed || generation != _requestGeneration) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: LoungeStatsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (stats) =>
          emit(state.copyWith(status: LoungeStatsStatus.success, stats: stats)),
    );
  }
}
