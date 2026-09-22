import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/usecases/base_usecase.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import '../../domain/usecases/kyc_usecases.dart';
import 'kyc_state.dart';

class KycCubit extends Cubit<KycState> {
  final SubmitKycUseCase _submitKycUseCase;
  final GetPendingKycReviewsUseCase _getPendingKycReviewsUseCase;
  final ReviewKycUseCase _reviewKycUseCase;

  KycCubit({
    required SubmitKycUseCase submitKycUseCase,
    required GetPendingKycReviewsUseCase getPendingKycReviewsUseCase,
    required ReviewKycUseCase reviewKycUseCase,
  })  : _submitKycUseCase = submitKycUseCase,
        _getPendingKycReviewsUseCase = getPendingKycReviewsUseCase,
        _reviewKycUseCase = reviewKycUseCase,
        super(const KycState());

  Future<void> submitKyc({
    required String userId,
    required Uint8List idCardBytes,
    required String idCardName,
    Uint8List? businessDocBytes,
    String? businessDocName,
  }) async {
    emit(state.copyWith(status: KycStatus.loading));
    final result = await _submitKycUseCase(SubmitKycParams(
      userId: userId,
      idCardBytes: idCardBytes,
      idCardName: idCardName,
      businessDocBytes: businessDocBytes,
      businessDocName: businessDocName,
    ));

    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.error('Submit KYC error: ${failure.message}');
        emit(state.copyWith(status: KycStatus.failure, errorMessage: failure.message));
      },
      (_) => emit(state.copyWith(status: KycStatus.success)),
    );
  }

  Future<void> loadPendingReviews() async {
    emit(state.copyWith(status: KycStatus.loading));
    final result = await _getPendingKycReviewsUseCase(const NoParams());

    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.error('Load pending reviews error: ${failure.message}');
        emit(state.copyWith(status: KycStatus.failure, errorMessage: failure.message));
      },
      (requests) => emit(state.copyWith(status: KycStatus.success, requests: requests)),
    );
  }

  Future<void> reviewKyc({
    required String userId,
    required bool approve,
    String? notes,
  }) async {
    emit(state.copyWith(status: KycStatus.loading));
    final result = await _reviewKycUseCase(ReviewKycParams(
      userId: userId,
      approve: approve,
      notes: notes,
    ));

    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.error('Review KYC error: ${failure.message}');
        emit(state.copyWith(status: KycStatus.failure, errorMessage: failure.message));
      },
      (_) => loadPendingReviews(),
    );
  }
}
