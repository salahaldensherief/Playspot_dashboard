import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/usecases/base_usecase.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import '../../domain/usecases/kyc_usecases.dart';
import 'kyc_state.dart';

class KycCubit extends Cubit<KycState> {
  int _generation = 0;
  bool _mutationInFlight = false;
  final SubmitKycUseCase _submitKycUseCase;
  final GetPendingKycReviewsUseCase _getPendingKycReviewsUseCase;
  final ReviewKycUseCase _reviewKycUseCase;

  KycCubit({
    required SubmitKycUseCase submitKycUseCase,
    required GetPendingKycReviewsUseCase getPendingKycReviewsUseCase,
    required ReviewKycUseCase reviewKycUseCase,
  }) : _submitKycUseCase = submitKycUseCase,
       _getPendingKycReviewsUseCase = getPendingKycReviewsUseCase,
       _reviewKycUseCase = reviewKycUseCase,
       super(const KycState());

  Future<void> submitKyc({
    required String userId,
    required String loungeId,
    required Uint8List idCardBytes,
    required String idCardName,
    Uint8List? businessDocBytes,
    String? businessDocName,
  }) async {
    if (isClosed || _mutationInFlight) return;
    _mutationInFlight = true;
    final generation = ++_generation;
    emit(state.copyWith(status: KycStatus.loading));
    final result = await _runMutation(
      () => _submitKycUseCase(
        SubmitKycParams(
          userId: userId,
          loungeId: loungeId,
          idCardBytes: idCardBytes,
          idCardName: idCardName,
          businessDocBytes: businessDocBytes,
          businessDocName: businessDocName,
        ),
      ),
    );

    _mutationInFlight = false;
    if (isClosed || generation != _generation) return;

    result.fold((failure) {
      AppLogger.error('Submit KYC error: ${failure.message}');
      emit(
        state.copyWith(
          status: KycStatus.failure,
          errorMessage: failure.message,
        ),
      );
    }, (_) => emit(state.copyWith(status: KycStatus.success)));
  }

  Future<void> loadPendingReviews() async {
    if (isClosed || _mutationInFlight) return;
    final generation = ++_generation;
    emit(state.copyWith(status: KycStatus.loading));
    final result = await _getPendingKycReviewsUseCase(const NoParams());

    if (isClosed || generation != _generation) return;

    result.fold(
      (failure) {
        AppLogger.error('Load pending reviews error: ${failure.message}');
        emit(
          state.copyWith(
            status: KycStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
      (requests) =>
          emit(state.copyWith(status: KycStatus.success, requests: requests)),
    );
  }

  Future<bool> reviewKyc({
    required String requestId,
    required int revision,
    required bool approve,
    String? notes,
  }) async {
    if (isClosed || _mutationInFlight) return false;
    _mutationInFlight = true;
    ++_generation;
    emit(state.copyWith(status: KycStatus.loading));
    final result = await _runMutation(
      () => _reviewKycUseCase(
        ReviewKycParams(
          requestId: requestId,
          revision: revision,
          approve: approve,
          notes: notes,
        ),
      ),
    );

    _mutationInFlight = false;
    if (isClosed) return false;

    final accepted = result.fold((failure) {
      AppLogger.error('Review KYC error: ${failure.message}');
      emit(
        state.copyWith(
          status: KycStatus.failure,
          errorMessage: failure.message,
        ),
      );
      return false;
    }, (_) => true);
    if (accepted) await loadPendingReviews();
    return accepted;
  }

  Future<Either<Failure, void>> _runMutation(
    Future<Either<Failure, void>> Function() operation,
  ) async {
    try {
      return await operation();
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    } finally {
      _mutationInFlight = false;
    }
  }
}
