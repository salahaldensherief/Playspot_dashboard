import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/usecases/base_usecase.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import '../../domain/usecases/payout_usecases.dart';
import 'payout_state.dart';

class PayoutCubit extends Cubit<PayoutState> {
  final GetPendingPayoutsOverviewUseCase _getPendingPayoutsOverviewUseCase;
  final GetAllPayoutsUseCase _getAllPayoutsUseCase;
  final CreatePayoutUseCase _createPayoutUseCase;
  final ApprovePayoutUseCase _approvePayoutUseCase;
  final StartPayoutProcessingUseCase _startPayoutProcessingUseCase;
  final CompletePayoutUseCase _completePayoutUseCase;
  final MarkPayoutPaidUseCase _markPayoutPaidUseCase;
  final FailPayoutUseCase _failPayoutUseCase;
  final CancelPayoutUseCase _cancelPayoutUseCase;
  final ResolvePayoutReviewUseCase _resolvePayoutReviewUseCase;
  final GetPayoutDetailsUseCase _getPayoutDetailsUseCase;
  final GetPayoutsByLoungeUseCase _getPayoutsByLoungeUseCase;

  PayoutCubit({
    required GetPendingPayoutsOverviewUseCase getPendingPayoutsOverviewUseCase,
    required GetAllPayoutsUseCase getAllPayoutsUseCase,
    required CreatePayoutUseCase createPayoutUseCase,
    required ApprovePayoutUseCase approvePayoutUseCase,
    required StartPayoutProcessingUseCase startPayoutProcessingUseCase,
    required CompletePayoutUseCase completePayoutUseCase,
    required MarkPayoutPaidUseCase markPayoutPaidUseCase,
    required FailPayoutUseCase failPayoutUseCase,
    required CancelPayoutUseCase cancelPayoutUseCase,
    required ResolvePayoutReviewUseCase resolvePayoutReviewUseCase,
    required GetPayoutDetailsUseCase getPayoutDetailsUseCase,
    required GetPayoutsByLoungeUseCase getPayoutsByLoungeUseCase,
  })  : _getPendingPayoutsOverviewUseCase = getPendingPayoutsOverviewUseCase,
        _getAllPayoutsUseCase = getAllPayoutsUseCase,
        _createPayoutUseCase = createPayoutUseCase,
        _approvePayoutUseCase = approvePayoutUseCase,
        _startPayoutProcessingUseCase = startPayoutProcessingUseCase,
        _completePayoutUseCase = completePayoutUseCase,
        _markPayoutPaidUseCase = markPayoutPaidUseCase,
        _failPayoutUseCase = failPayoutUseCase,
        _cancelPayoutUseCase = cancelPayoutUseCase,
        _resolvePayoutReviewUseCase = resolvePayoutReviewUseCase,
        _getPayoutDetailsUseCase = getPayoutDetailsUseCase,
        _getPayoutsByLoungeUseCase = getPayoutsByLoungeUseCase,
        super(const PayoutState());

  Future<void> loadSuperAdminPayouts() async {
    emit(state.copyWith(status: PayoutCubitStatus.loading));

    final pendingResult = await _getPendingPayoutsOverviewUseCase(const NoParams());
    final allResult = await _getAllPayoutsUseCase(const NoParams());

    if (isClosed) return;

    pendingResult.fold(
      (failure) {
        AppLogger.error('Failed to load pending payouts: ${failure.message}');
        emit(state.copyWith(status: PayoutCubitStatus.failure, errorMessage: failure.message));
      },
      (pending) {
        allResult.fold(
          (failure) {
            AppLogger.error('Failed to load all payouts: ${failure.message}');
            emit(state.copyWith(status: PayoutCubitStatus.failure, errorMessage: failure.message));
          },
          (all) {
            emit(state.copyWith(
              status: PayoutCubitStatus.success,
              pendingOverviews: pending,
              allPayouts: all,
            ));
          },
        );
      },
    );
  }

  Future<void> loadLoungePayouts(String loungeId) async {
    emit(state.copyWith(status: PayoutCubitStatus.loading));
    final result = await _getPayoutsByLoungeUseCase(loungeId);

    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.error('Failed to load lounge payouts: ${failure.message}');
        emit(state.copyWith(status: PayoutCubitStatus.failure, errorMessage: failure.message));
      },
      (payouts) {
        emit(state.copyWith(
          status: PayoutCubitStatus.success,
          loungePayouts: payouts,
        ));
      },
    );
  }

  Future<void> loadPayoutDetails(String payoutId) async {
    final result = await _getPayoutDetailsUseCase(payoutId);
    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.error('Failed to load payout details: ${failure.message}');
        emit(state.copyWith(status: PayoutCubitStatus.failure, errorMessage: failure.message));
      },
      (details) {
        emit(state.copyWith(selectedPayoutDetails: details));
      },
    );
  }

  Future<bool> createPayout({
    required String loungeId,
    required String periodStart,
    required String periodEnd,
  }) async {
    emit(state.copyWith(status: PayoutCubitStatus.loading));
    final result = await _createPayoutUseCase(CreatePayoutParams(
      loungeId: loungeId,
      periodStart: periodStart,
      periodEnd: periodEnd,
    ));

    if (isClosed) return false;

    return result.fold(
      (failure) {
        AppLogger.error('Failed to create payout: ${failure.message}');
        emit(state.copyWith(status: PayoutCubitStatus.failure, errorMessage: failure.message));
        return false;
      },
      (data) {
        emit(state.copyWith(
          status: PayoutCubitStatus.actionSuccess,
          successMessage: 'تم إنشاء دفعة التحويل بنجاح',
        ));
        loadSuperAdminPayouts();
        return true;
      },
    );
  }

  Future<void> approvePayout(String payoutId, {String? notes}) async {
    emit(state.copyWith(status: PayoutCubitStatus.loading));
    final result = await _approvePayoutUseCase(ApprovePayoutParams(payoutId: payoutId, notes: notes));

    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.error('Failed to approve payout: ${failure.message}');
        emit(state.copyWith(status: PayoutCubitStatus.failure, errorMessage: failure.message));
      },
      (_) {
        emit(state.copyWith(
          status: PayoutCubitStatus.actionSuccess,
          successMessage: 'تم اعتماد التحويل بنجاح',
        ));
        loadSuperAdminPayouts();
      },
    );
  }

  Future<void> startPayoutProcessing(String payoutId) async {
    emit(state.copyWith(status: PayoutCubitStatus.loading));
    final result = await _startPayoutProcessingUseCase(payoutId);

    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.error('Failed to start payout processing: ${failure.message}');
        emit(state.copyWith(status: PayoutCubitStatus.failure, errorMessage: failure.message));
      },
      (_) {
        emit(state.copyWith(
          status: PayoutCubitStatus.actionSuccess,
          successMessage: 'تم بدء معالجة التحويل',
        ));
        loadSuperAdminPayouts();
      },
    );
  }

  Future<void> completePayout({
    required String payoutId,
    required String transferMethod,
    required String transferReference,
    String? receiptUrl,
    String? notes,
  }) async {
    emit(state.copyWith(status: PayoutCubitStatus.loading));
    final result = await _completePayoutUseCase(CompletePayoutParams(
      payoutId: payoutId,
      transferMethod: transferMethod,
      transferReference: transferReference,
      receiptUrl: receiptUrl,
      notes: notes,
    ));

    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.error('Failed to complete payout: ${failure.message}');
        emit(state.copyWith(status: PayoutCubitStatus.failure, errorMessage: failure.message));
      },
      (_) {
        emit(state.copyWith(
          status: PayoutCubitStatus.actionSuccess,
          successMessage: 'تم إتمام التحويل بنجاح',
        ));
        loadSuperAdminPayouts();
      },
    );
  }

  Future<void> markPayoutPaid(String payoutId, {String? notes}) async {
    emit(state.copyWith(status: PayoutCubitStatus.loading));
    final result = await _markPayoutPaidUseCase(MarkPayoutPaidParams(payoutId: payoutId, notes: notes));

    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.error('Failed to mark payout paid: ${failure.message}');
        emit(state.copyWith(status: PayoutCubitStatus.failure, errorMessage: failure.message));
      },
      (_) {
        emit(state.copyWith(
          status: PayoutCubitStatus.actionSuccess,
          successMessage: 'تم تأكيد دفع الحوالة',
        ));
        loadSuperAdminPayouts();
      },
    );
  }

  Future<void> failPayout(String payoutId, String reason) async {
    emit(state.copyWith(status: PayoutCubitStatus.loading));
    final result = await _failPayoutUseCase(FailPayoutParams(payoutId: payoutId, reason: reason));

    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.error('Failed to fail payout: ${failure.message}');
        emit(state.copyWith(status: PayoutCubitStatus.failure, errorMessage: failure.message));
      },
      (_) {
        emit(state.copyWith(
          status: PayoutCubitStatus.actionSuccess,
          successMessage: 'تم تسجيل فشل التحويل',
        ));
        loadSuperAdminPayouts();
      },
    );
  }

  Future<void> cancelPayout(String payoutId, String reason) async {
    emit(state.copyWith(status: PayoutCubitStatus.loading));
    final result = await _cancelPayoutUseCase(CancelPayoutParams(payoutId: payoutId, reason: reason));

    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.error('Failed to cancel payout: ${failure.message}');
        emit(state.copyWith(status: PayoutCubitStatus.failure, errorMessage: failure.message));
      },
      (_) {
        emit(state.copyWith(
          status: PayoutCubitStatus.actionSuccess,
          successMessage: 'تم إلغاء التحويل بنجاح',
        ));
        loadSuperAdminPayouts();
      },
    );
  }

  Future<void> resolvePayoutReview({
    required String payoutId,
    required String resolution,
    required String reason,
  }) async {
    emit(state.copyWith(status: PayoutCubitStatus.loading));
    final result = await _resolvePayoutReviewUseCase(ResolvePayoutReviewParams(
      payoutId: payoutId,
      resolution: resolution,
      reason: reason,
    ));

    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.error('Failed to resolve payout review: ${failure.message}');
        emit(state.copyWith(status: PayoutCubitStatus.failure, errorMessage: failure.message));
      },
      (_) {
        emit(state.copyWith(
          status: PayoutCubitStatus.actionSuccess,
          successMessage: 'تم إنهاء المراجعة بنجاح',
        ));
        loadSuperAdminPayouts();
      },
    );
  }
}
