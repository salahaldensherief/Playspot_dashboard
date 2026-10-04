import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/moderation_remote_data_source.dart';
import '../../data/moderation_failure_mapper.dart';
import 'moderation_state.dart';

class ModerationCubit extends Cubit<ModerationState> {
  final ModerationRemoteDataSource dataSource;
  int _loadGeneration = 0;
  bool _mutationInFlight = false;

  ModerationCubit({required this.dataSource}) : super(const ModerationState());

  Future<void> createBanRequest({
    required String loungeId,
    required String userId,
    String? bookingId,
    required String reason,
    String? evidenceNotes,
  }) => _runMutation(
    () => dataSource.createBanRequest(
      loungeId: loungeId,
      userId: userId,
      bookingId: bookingId,
      reason: reason,
      evidenceNotes: evidenceNotes,
    ),
    'moderation_report_submitted',
  );

  Future<void> loadLoungeBanRequests(String loungeId) async {
    if (isClosed) return;
    final generation = ++_loadGeneration;
    emit(state.copyWith(status: ModerationStatus.loading, banRequests: []));
    try {
      final requests = await dataSource.getLoungeBanRequests(loungeId);
      if (isClosed || generation != _loadGeneration) return;
      emit(
        state.copyWith(status: ModerationStatus.success, banRequests: requests),
      );
    } catch (error) {
      if (isClosed || generation != _loadGeneration) return;
      emit(
        state.copyWith(
          status: ModerationStatus.error,
          errorMessage: moderationFailure(error).message,
        ),
      );
    }
  }

  Future<void> loadPendingBanRequests() async {
    if (isClosed) return;
    final generation = ++_loadGeneration;
    emit(state.copyWith(status: ModerationStatus.loading, pendingRequests: []));
    try {
      final requests = await dataSource.getPendingBanRequests();
      if (isClosed || generation != _loadGeneration) return;
      emit(
        state.copyWith(
          status: ModerationStatus.success,
          pendingRequests: requests,
        ),
      );
    } catch (error) {
      if (isClosed || generation != _loadGeneration) return;
      emit(
        state.copyWith(
          status: ModerationStatus.error,
          errorMessage: moderationFailure(error).message,
        ),
      );
    }
  }

  Future<void> approveLoungeBan(String requestId, {String? adminNotes}) =>
      _runMutation(
        () => dataSource.approveLoungeBanRequest(
          requestId,
          adminNotes: adminNotes,
        ),
        'moderation_lounge_ban_approved',
        reloadQueue: true,
      );

  Future<void> approveGlobalBan(String requestId, {String? adminNotes}) =>
      _runMutation(
        () => dataSource.approveGlobalBanRequest(
          requestId,
          adminNotes: adminNotes,
        ),
        'moderation_global_ban_approved',
        reloadQueue: true,
      );

  Future<void> rejectBan(String requestId, {String? adminNotes}) =>
      _runMutation(
        () => dataSource.rejectBanRequest(requestId, adminNotes: adminNotes),
        'moderation_report_rejected',
        reloadQueue: true,
      );

  Future<void> suspendLounge(String loungeId, {required String reason}) =>
      _runMutation(
        () => dataSource.suspendLounge(loungeId, reason: reason),
        'moderation_lounge_suspended',
      );

  Future<void> _runMutation(
    Future<void> Function() submit,
    String successKey, {
    bool reloadQueue = false,
  }) async {
    if (isClosed || _mutationInFlight) return;
    _mutationInFlight = true;
    emit(state.copyWith(isSubmitting: true));
    try {
      await submit();
      if (isClosed) return;
      emit(state.copyWith(isSubmitting: false, successMessage: successKey));
      if (reloadQueue) await loadPendingBanRequests();
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: moderationFailure(error).message,
        ),
      );
    } finally {
      _mutationInFlight = false;
    }
  }
}
