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

  Future<void> createLoungeAndAdmin({
    required Lounge lounge,
    required String ownerName,
    required String ownerEmail,
    required String ownerPassword,
  }) async {
    emit(LoungeLoading());
    
    // 1. Create Lounge
    final loungeResult = await repository.createLounge(lounge);
    
    await loungeResult.fold(
      (failure) async => emit(LoungeError(failure.message)),
      (loungeId) async {
        // 2. Create Admin linked to this Lounge
        final adminResult = await repository.createLoungeAdmin(
          email: ownerEmail,
          password: ownerPassword,
          name: ownerName,
          loungeId: loungeId,
        );
        
        adminResult.fold(
          (failure) => emit(LoungeError('Lounge created but admin failed: ${failure.message}')),
          (_) {
            fetchLounges(); // Refresh the list
          },
        );
      },
    );
  }
}
