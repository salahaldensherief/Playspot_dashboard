import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/lounge.dart';
import '../../domain/repositories/lounge_repository.dart';
import 'lounge_state.dart';

class LoungeCubit extends Cubit<LoungeState> {
  final LoungeRepository repository;

  LoungeCubit(this.repository) : super(const LoungeState());

  Future<void> fetchLounges() async {
    emit(state.copyWith(status: LoungeStatus.loading));
    final result = await repository.getLounges();
    result.fold(
      (failure) => emit(state.copyWith(
        status: LoungeStatus.failure,
        errorMessage: failure.message,
      )),
      (lounges) => emit(state.copyWith(
        status: LoungeStatus.success,
        lounges: lounges,
      )),
    );
  }

  Future<void> createLoungeAndAdmin({
    required Lounge lounge,
    required String ownerName,
    required String ownerEmail,
    required String ownerPassword,
  }) async {
    emit(state.copyWith(status: LoungeStatus.loading));
    
    // 1. Create Lounge
    final loungeResult = await repository.createLounge(lounge);
    
    await loungeResult.fold(
      (failure) async => emit(state.copyWith(
        status: LoungeStatus.failure,
        errorMessage: failure.message,
      )),
      (loungeId) async {
        // 2. Create Admin linked to this Lounge
        final adminResult = await repository.createLoungeAdmin(
          email: ownerEmail,
          password: ownerPassword,
          name: ownerName,
          loungeId: loungeId,
        );
        
        adminResult.fold(
          (failure) => emit(state.copyWith(
            status: LoungeStatus.failure,
            errorMessage: 'Lounge created but admin failed: ${failure.message}',
          )),
          (_) {
            fetchLounges(); // Refresh the list
          },
        );
      },
    );
  }

  Future<void> updateLoungeLocation(String loungeId, double lat, double lng) async {
    await repository.updateLoungeLocation(loungeId, lat, lng);
  }

  Future<void> updateLounge(Lounge lounge) async {
    emit(state.copyWith(status: LoungeStatus.loading));
    final result = await repository.updateLounge(lounge);
    result.fold(
      (failure) => emit(state.copyWith(
        status: LoungeStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => fetchLounges(),
    );
  }

  Future<void> deleteLounge(String id) async {
    emit(state.copyWith(status: LoungeStatus.loading));
    final result = await repository.deleteLounge(id);
    result.fold(
      (failure) => emit(state.copyWith(
        status: LoungeStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => fetchLounges(),
    );
  }
}
