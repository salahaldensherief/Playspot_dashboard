import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';
import 'package:play_spot_dashboard/features/lounges/domain/repositories/lounge_repository.dart';

part 'lounge_state.dart';

class LoungeCubit extends Cubit<LoungeState> {
  final LoungeRepository repository;

  LoungeCubit(this.repository) : super(LoungeInitial());

  Future<void> fetchLounges() async {
    emit(LoungeLoading());
    final result = await repository.getLounges();
    result.fold(
      (failure) => emit(LoungeError(failure.message)),
      (lounges) => emit(LoungeLoaded(lounges)),
    );
  }
}
