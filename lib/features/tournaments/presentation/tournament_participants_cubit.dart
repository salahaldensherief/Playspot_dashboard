import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import 'package:play_spot_dashboard/core/utils/optimistic_update_extension.dart';
import '../domain/entities/tournament_participant_entity.dart';
import '../domain/usecases/tournament_participant_usecases.dart';
import 'tournament_participants_state.dart';

class TournamentParticipantsCubit extends Cubit<TournamentParticipantsState> {
  final GetTournamentParticipantsUseCase _getParticipantsUseCase;
  final ApproveParticipantPaymentUseCase _approvePaymentUseCase;
  final RejectParticipantPaymentUseCase _rejectPaymentUseCase;
  final RecordCashPaymentUseCase _recordCashPaymentUseCase;
  final PromoteWaitlistUseCase _promoteWaitlistUseCase;
  final CheckInParticipantUseCase _checkInParticipantUseCase;
  final WithdrawParticipantUseCase _withdrawParticipantUseCase;

  TournamentParticipantsCubit({
    required GetTournamentParticipantsUseCase getParticipantsUseCase,
    required ApproveParticipantPaymentUseCase approvePaymentUseCase,
    required RejectParticipantPaymentUseCase rejectPaymentUseCase,
    required RecordCashPaymentUseCase recordCashPaymentUseCase,
    required PromoteWaitlistUseCase promoteWaitlistUseCase,
    required CheckInParticipantUseCase checkInParticipantUseCase,
    required WithdrawParticipantUseCase withdrawParticipantUseCase,
  })  : _getParticipantsUseCase = getParticipantsUseCase,
        _approvePaymentUseCase = approvePaymentUseCase,
        _rejectPaymentUseCase = rejectPaymentUseCase,
        _recordCashPaymentUseCase = recordCashPaymentUseCase,
        _promoteWaitlistUseCase = promoteWaitlistUseCase,
        _checkInParticipantUseCase = checkInParticipantUseCase,
        _withdrawParticipantUseCase = withdrawParticipantUseCase,
        super(const TournamentParticipantsState());

  Future<void> loadParticipants(String tournamentId) async {
    emit(state.copyWith(status: TournamentParticipantsStatus.loading));
    final result = await _getParticipantsUseCase(tournamentId);
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.error('Failed to load participants: ${failure.message}');
        emit(state.copyWith(
          status: TournamentParticipantsStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (list) => emit(state.copyWith(
        status: TournamentParticipantsStatus.success,
        participants: list,
      )),
    );
  }

  Future<void> approvePayment(String participantId) async {
    final original = List<TournamentParticipantEntity>.from(state.participants);
    await optimisticUpdate<void>(
      apply: (curr) => curr.copyWith(
        status: TournamentParticipantsStatus.actionSuccess,
        participants: curr.participants.map((p) {
          if (p.id == participantId) {
            return p.copyWith(
              paymentStatus: ParticipantPaymentStatus.approved,
              participantStatus: ParticipantStatus.confirmed,
            );
          }
          return p;
        }).toList(),
        successMessage: 'تم اعتماد إيصال الدفع بنجاح',
      ),
      onServer: () => _approvePaymentUseCase(participantId),
      rollback: (curr, failure) {
        AppLogger.error('Failed to approve payment: ${failure.message}');
        return curr.copyWith(
          status: TournamentParticipantsStatus.failure,
          participants: original,
          errorMessage: failure.message,
        );
      },
    );
  }

  Future<void> rejectPayment(String participantId, String reason) async {
    final original = List<TournamentParticipantEntity>.from(state.participants);
    await optimisticUpdate<void>(
      apply: (curr) => curr.copyWith(
        status: TournamentParticipantsStatus.actionSuccess,
        participants: curr.participants.map((p) {
          if (p.id == participantId) {
            return p.copyWith(
              paymentStatus: ParticipantPaymentStatus.rejected,
              rejectionReason: reason,
            );
          }
          return p;
        }).toList(),
        successMessage: 'تم رفض إيصال الدفع',
      ),
      onServer: () => _rejectPaymentUseCase(RejectPaymentParams(participantId: participantId, reason: reason)),
      rollback: (curr, failure) {
        AppLogger.error('Failed to reject payment: ${failure.message}');
        return curr.copyWith(
          status: TournamentParticipantsStatus.failure,
          participants: original,
          errorMessage: failure.message,
        );
      },
    );
  }

  Future<void> recordCashPayment(String participantId) async {
    final original = List<TournamentParticipantEntity>.from(state.participants);
    await optimisticUpdate<void>(
      apply: (curr) => curr.copyWith(
        status: TournamentParticipantsStatus.actionSuccess,
        participants: curr.participants.map((p) {
          if (p.id == participantId) {
            return p.copyWith(
              paymentStatus: ParticipantPaymentStatus.approved,
              participantStatus: ParticipantStatus.confirmed,
            );
          }
          return p;
        }).toList(),
        successMessage: 'تم تسجيل الدفع النقدي في الصالة',
      ),
      onServer: () => _recordCashPaymentUseCase(participantId),
      rollback: (curr, failure) {
        AppLogger.error('Failed to record cash payment: ${failure.message}');
        return curr.copyWith(
          status: TournamentParticipantsStatus.failure,
          participants: original,
          errorMessage: failure.message,
        );
      },
    );
  }

  Future<void> promoteWaitlist(String tournamentId) async {
    emit(state.copyWith(status: TournamentParticipantsStatus.loading));
    final result = await _promoteWaitlistUseCase(tournamentId);
    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.error('Failed to promote waitlist: ${failure.message}');
        emit(state.copyWith(
          status: TournamentParticipantsStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (_) {
        emit(state.copyWith(
          status: TournamentParticipantsStatus.actionSuccess,
          successMessage: 'تم ترقية أول لاعب في قائمة الانتظار بنجاح',
        ));
        loadParticipants(tournamentId);
      },
    );
  }

  Future<void> checkInParticipant(String participantId) async {
    final original = List<TournamentParticipantEntity>.from(state.participants);
    await optimisticUpdate<void>(
      apply: (curr) => curr.copyWith(
        status: TournamentParticipantsStatus.actionSuccess,
        participants: curr.participants.map((p) {
          if (p.id == participantId) {
            return p.copyWith(
              isCheckedIn: true,
              checkedInAt: DateTime.now(),
            );
          }
          return p;
        }).toList(),
        successMessage: 'تم تسجيل حضور اللاعب',
      ),
      onServer: () => _checkInParticipantUseCase(participantId),
      rollback: (curr, failure) {
        AppLogger.error('Failed to check in participant: ${failure.message}');
        return curr.copyWith(
          status: TournamentParticipantsStatus.failure,
          participants: original,
          errorMessage: failure.message,
        );
      },
    );
  }

  Future<void> withdrawParticipant(String participantId) async {
    final original = List<TournamentParticipantEntity>.from(state.participants);
    await optimisticUpdate<void>(
      apply: (curr) => curr.copyWith(
        status: TournamentParticipantsStatus.actionSuccess,
        participants: curr.participants.map((p) {
          if (p.id == participantId) {
            return p.copyWith(
              participantStatus: ParticipantStatus.withdrawn,
            );
          }
          return p;
        }).toList(),
        successMessage: 'تم انسحاب المشارك بنجاح',
      ),
      onServer: () => _withdrawParticipantUseCase(participantId),
      rollback: (curr, failure) {
        AppLogger.error('Failed to withdraw participant: ${failure.message}');
        return curr.copyWith(
          status: TournamentParticipantsStatus.failure,
          participants: original,
          errorMessage: failure.message,
        );
      },
    );
  }
}
