import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_lounge_owner_stats_usecase.dart';
import 'lounge_stats_state.dart';

class LoungeStatsCubit extends Cubit<LoungeStatsState> {
  final GetLoungeOwnerStatsUseCase getLoungeOwnerStatsUseCase;

  LoungeStatsCubit(this.getLoungeOwnerStatsUseCase) : super(const LoungeStatsState());

  Future<void> fetchStats(String? loungeId) async {
    emit(state.copyWith(status: LoungeStatsStatus.loading));

    final result = await getLoungeOwnerStatsUseCase(loungeId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: LoungeStatsStatus.failure,
        errorMessage: failure.message,
      )),
      (stats) => emit(state.copyWith(
        status: LoungeStatsStatus.success,
        stats: stats,
      )),
    );
  }
}
