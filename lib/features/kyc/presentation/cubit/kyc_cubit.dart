import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/kyc_repository.dart';
import 'kyc_state.dart';
import 'dart:typed_data';

class KycCubit extends Cubit<KycState> {
  final KycRepository _repository;

  KycCubit(this._repository) : super(const KycState());

  Future<void> submitKyc({
    required String userId,
    required Uint8List idCardBytes,
    required String idCardName,
    Uint8List? businessDocBytes,
    String? businessDocName,
  }) async {
    emit(state.copyWith(status: KycStatus.loading));
    final result = await _repository.submitKyc(
      userId: userId,
      idCardBytes: idCardBytes,
      idCardName: idCardName,
      businessDocBytes: businessDocBytes,
      businessDocName: businessDocName,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(status: KycStatus.failure, errorMessage: failure.message)),
      (_) => emit(state.copyWith(status: KycStatus.success)),
    );
  }

  Future<void> loadPendingReviews() async {
    emit(state.copyWith(status: KycStatus.loading));
    final result = await _repository.getPendingReviews();

    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(status: KycStatus.failure, errorMessage: failure.message)),
      (requests) => emit(state.copyWith(status: KycStatus.success, requests: requests)),
    );
  }

  Future<void> reviewKyc({
    required String userId,
    required bool approve,
    String? notes,
  }) async {
    emit(state.copyWith(status: KycStatus.loading));
    final result = await _repository.reviewKyc(
      userId: userId,
      approve: approve,
      notes: notes,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(status: KycStatus.failure, errorMessage: failure.message)),
      (_) => loadPendingReviews(),
    );
  }
}
