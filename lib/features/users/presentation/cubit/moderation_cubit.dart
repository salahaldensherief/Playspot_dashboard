import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/moderation_remote_data_source.dart';
import 'moderation_state.dart';

class ModerationCubit extends Cubit<ModerationState> {
  final ModerationRemoteDataSource dataSource;

  ModerationCubit({required this.dataSource}) : super(const ModerationState());

  Future<void> createBanRequest({
    required String loungeId,
    required String userId,
    String? bookingId,
    required String reason,
    String? evidenceNotes,
  }) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null, successMessage: null));
    try {
      await dataSource.createBanRequest(
        loungeId: loungeId,
        userId: userId,
        bookingId: bookingId,
        reason: reason,
        evidenceNotes: evidenceNotes,
      );
      emit(state.copyWith(
        isSubmitting: false,
        successMessage: 'تم إرسال طلب البلاغ بنجاح وسيتم مراجعته من الإدارة',
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: 'فشل إرسال طلب البلاغ: $e',
      ));
    }
  }

  Future<void> loadLoungeBanRequests(String loungeId) async {
    emit(state.copyWith(status: ModerationStatus.loading));
    try {
      final requests = await dataSource.getLoungeBanRequests(loungeId);
      emit(state.copyWith(
        status: ModerationStatus.success,
        banRequests: requests,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ModerationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> loadPendingBanRequests() async {
    emit(state.copyWith(status: ModerationStatus.loading));
    try {
      final requests = await dataSource.getPendingBanRequests();
      emit(state.copyWith(
        status: ModerationStatus.success,
        pendingRequests: requests,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ModerationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> approveLoungeBan(String requestId, {String? adminNotes}) async {
    emit(state.copyWith(isSubmitting: true));
    try {
      await dataSource.approveLoungeBanRequest(requestId, adminNotes: adminNotes);
      emit(state.copyWith(isSubmitting: false, successMessage: 'تم حظر المستخدم من الصالة بنجاح'));
      await loadPendingBanRequests();
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.toString()));
    }
  }

  Future<void> approveGlobalBan(String requestId, {String? adminNotes}) async {
    emit(state.copyWith(isSubmitting: true));
    try {
      await dataSource.approveGlobalBanRequest(requestId, adminNotes: adminNotes);
      emit(state.copyWith(isSubmitting: false, successMessage: 'تم الحظر الكلي للمستخدم بنجاح'));
      await loadPendingBanRequests();
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.toString()));
    }
  }

  Future<void> rejectBan(String requestId, {String? adminNotes}) async {
    emit(state.copyWith(isSubmitting: true));
    try {
      await dataSource.rejectBanRequest(requestId, adminNotes: adminNotes);
      emit(state.copyWith(isSubmitting: false, successMessage: 'تم رفض طلب البلاغ'));
      await loadPendingBanRequests();
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.toString()));
    }
  }

  Future<void> suspendLounge(String loungeId, {required String reason}) async {
    emit(state.copyWith(isSubmitting: true));
    try {
      await dataSource.suspendLounge(loungeId, reason: reason);
      emit(state.copyWith(isSubmitting: false, successMessage: 'تم تعليق الصالة بنجاح'));
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.toString()));
    }
  }
}
