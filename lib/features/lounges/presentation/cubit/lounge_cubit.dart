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
    
    if (isClosed) return;

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
    
    final loungeResult = await repository.createLounge(lounge);
    
    if (isClosed) return;

    await loungeResult.fold(
      (failure) async => emit(state.copyWith(
        status: LoungeStatus.failure,
        errorMessage: failure.message,
      )),
      (loungeId) async {
        final adminResult = await repository.createLoungeAdmin(
          email: ownerEmail,
          password: ownerPassword,
          name: ownerName,
          loungeId: loungeId,
        );
        
        if (isClosed) return;

        adminResult.fold(
          (failure) => emit(state.copyWith(
            status: LoungeStatus.failure,
            errorMessage: 'Lounge created but admin failed: ${failure.message}',
          )),
          (_) {
            fetchLounges();
          },
        );
      },
    );
  }

  Future<void> updateLoungeLocation(String loungeId, double lat, double lng) async {
    await repository.updateLoungeLocation(loungeId, lat, lng);
  }

  Future<void> toggleLoungeStatus(String loungeId, bool isOpen) async {
    // تحديث تفاؤلي للواجهة (Optimistic UI)
    final currentState = state;
    if (currentState.lounges.isNotEmpty) {
      final updatedLounges = currentState.lounges.map((l) {
        if (l.id == loungeId) return l.copyWith(isOpen: isOpen);
        return l;
      }).toList();
      emit(state.copyWith(lounges: updatedLounges));
    }

    final result = await repository.toggleLoungeOpenStatus(loungeId, isOpen);
    result.fold(
      (failure) {
        emit(state.copyWith(status: LoungeStatus.failure, errorMessage: failure.message));
        fetchLounges(); // إعادة الجلب في حالة الخطأ لاستعادة الحالة الصحيحة
      },
      (_) => null,
    );
  }

  Future<void> updateLounge(Lounge lounge) async {
    emit(state.copyWith(status: LoungeStatus.loading));
    final result = await repository.updateLounge(lounge);
    
    if (isClosed) return;

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
    
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: LoungeStatus.failure,
        errorMessage: failure.message,
      )),
      (_) => fetchLounges(),
    );
  }
}
