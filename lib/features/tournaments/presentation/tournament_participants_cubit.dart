import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/utils/optimistic_update_extension.dart';
import '../domain/entities/tournament_participant_entity.dart';
import '../domain/repositories/tournament_repository.dart';
import 'tournament_participants_state.dart';

class TournamentParticipantsCubit extends Cubit<TournamentParticipantsState> {
  final TournamentRepository repository;

  TournamentParticipantsCubit(this.repository) : super(const TournamentParticipantsState());

  Future<void> loadParticipants(String tournamentId) async {
    emit(state.copyWith(status: TournamentParticipantsStatus.loading));
    final result = await repository.getParticipants(tournamentId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentParticipantsStatus.failure,
        errorMessage: failure.message,
      )),
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
      onServer: () => repository.approvePayment(participantId),
      rollback: (curr, failure) => curr.copyWith(
        status: TournamentParticipantsStatus.failure,
        participants: original,
        errorMessage: failure.message,
      ),
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
      onServer: () => repository.rejectPayment(participantId, reason),
      rollback: (curr, failure) => curr.copyWith(
        status: TournamentParticipantsStatus.failure,
        participants: original,
        errorMessage: failure.message,
      ),
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
      onServer: () => repository.recordCashPayment(participantId),
      rollback: (curr, failure) => curr.copyWith(
        status: TournamentParticipantsStatus.failure,
        participants: original,
        errorMessage: failure.message,
      ),
    );
  }

  Future<void> promoteWaitlist(String tournamentId) async {
    emit(state.copyWith(status: TournamentParticipantsStatus.loading));
    final result = await repository.promoteWaitlist(tournamentId);
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentParticipantsStatus.failure,
        errorMessage: failure.message,
      )),
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
      onServer: () => repository.checkInParticipant(participantId),
      rollback: (curr, failure) => curr.copyWith(
        status: TournamentParticipantsStatus.failure,
        participants: original,
        errorMessage: failure.message,
      ),
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
      onServer: () => repository.withdrawParticipant(participantId),
      rollback: (curr, failure) => curr.copyWith(
        status: TournamentParticipantsStatus.failure,
        participants: original,
        errorMessage: failure.message,
      ),
    );
  }
}
