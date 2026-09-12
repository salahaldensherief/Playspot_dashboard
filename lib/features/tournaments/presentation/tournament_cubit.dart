import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/entities/tournament_entity.dart';
import '../domain/entities/tournament_match_entity.dart';
import '../domain/repositories/tournament_repository.dart';
import 'tournament_state.dart';

class TournamentCubit extends Cubit<TournamentState> {
  final TournamentRepository repository;
  StreamSubscription<List<TournamentMatchEntity>>? _disputesSubscription;

  TournamentCubit(this.repository) : super(const TournamentState());

  void setTab(int index) {
    emit(state.copyWith(selectedTab: index));
  }

  Future<void> loadTournaments({String? loungeId, String? status}) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await repository.getTournaments(
      loungeId: loungeId,
      status: status,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentCubitStatus.failure,
        errorMessage: failure.message,
      )),
      (list) {
        TournamentEntity? currentSelected = state.selectedTournament;
        if (currentSelected != null) {
          final updatedSelected = list.where((t) => t.id == currentSelected?.id).firstOrNull;
          if (updatedSelected != null) {
            currentSelected = updatedSelected;
          }
        } else if (list.isNotEmpty) {
          currentSelected = list.first;
        }

        emit(state.copyWith(
          status: TournamentCubitStatus.success,
          tournaments: list,
          selectedTournament: currentSelected,
        ));

        if (currentSelected != null) {
          _refreshSelectedTournamentData(currentSelected.id);
        }
      },
    );
  }

  void selectTournament(TournamentEntity tournament) {
    emit(state.copyWith(selectedTournament: tournament));
    _refreshSelectedTournamentData(tournament.id);
  }

  Future<void> _refreshSelectedTournamentData(String tournamentId) async {
    loadParticipants(tournamentId);
    loadMatches(tournamentId);
    loadAuditLogs(tournamentId);
    startWatchingDisputes(tournamentId);
  }

  Future<void> createTournament(TournamentEntity tournament) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await repository.createTournament(tournament);

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentCubitStatus.failure,
        errorMessage: failure.message,
      )),
      (created) {
        final updatedList = [created, ...state.tournaments];
        emit(state.copyWith(
          status: TournamentCubitStatus.actionSuccess,
          tournaments: updatedList,
          selectedTournament: created,
          successMessage: 'تم إنشاء البطولة بنجاح',
        ));
        _refreshSelectedTournamentData(created.id);
      },
    );
  }

  Future<void> updateTournament(TournamentEntity tournament) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await repository.updateTournament(tournament);

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentCubitStatus.failure,
        errorMessage: failure.message,
      )),
      (updated) {
        final list = state.tournaments.map((t) => t.id == updated.id ? updated : t).toList();
        emit(state.copyWith(
          status: TournamentCubitStatus.actionSuccess,
          tournaments: list,
          selectedTournament: updated,
          successMessage: 'تم تعديل بيانات البطولة بنجاح',
        ));
      },
    );
  }

  Future<void> publishTournament(String tournamentId) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await repository.publishTournament(tournamentId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentCubitStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          status: TournamentCubitStatus.actionSuccess,
          successMessage: 'تم نشر البطولة بنجاح',
        ));
        loadTournaments();
      },
    );
  }

  Future<void> cancelTournament(String tournamentId, String reason) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await repository.cancelTournament(tournamentId, reason);

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentCubitStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          status: TournamentCubitStatus.actionSuccess,
          successMessage: 'تم إلغاء البطولة',
        ));
        loadTournaments();
      },
    );
  }

  Future<void> deleteDraftTournament(String tournamentId) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await repository.deleteDraftTournament(tournamentId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentCubitStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        final list = state.tournaments.where((t) => t.id != tournamentId).toList();
        emit(state.copyWith(
          status: TournamentCubitStatus.actionSuccess,
          tournaments: list,
          clearSelectedTournament: state.selectedTournament?.id == tournamentId,
          successMessage: 'تم حذف مسودة البطولة بنجاح',
        ));
      },
    );
  }

  Future<void> loadParticipants(String tournamentId) async {
    final result = await repository.getParticipants(tournamentId);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (list) => emit(state.copyWith(participants: list)),
    );
  }

  Future<void> approvePayment(String participantId) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await repository.approvePayment(participantId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentCubitStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          status: TournamentCubitStatus.actionSuccess,
          successMessage: 'تم اعتماد إيصال الدفع بنجاح',
        ));
        if (state.selectedTournament != null) {
          loadParticipants(state.selectedTournament!.id);
        }
      },
    );
  }

  Future<void> rejectPayment(String participantId, String reason) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await repository.rejectPayment(participantId, reason);

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentCubitStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          status: TournamentCubitStatus.actionSuccess,
          successMessage: 'تم رفض إيصال الدفع',
        ));
        if (state.selectedTournament != null) {
          loadParticipants(state.selectedTournament!.id);
        }
      },
    );
  }

  Future<void> recordCashPayment(String participantId) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await repository.recordCashPayment(participantId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentCubitStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          status: TournamentCubitStatus.actionSuccess,
          successMessage: 'تم تسجيل الدفع النقدي في الصالة',
        ));
        if (state.selectedTournament != null) {
          loadParticipants(state.selectedTournament!.id);
        }
      },
    );
  }

  Future<void> checkInParticipant(String participantId) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await repository.checkInParticipant(participantId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentCubitStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          status: TournamentCubitStatus.actionSuccess,
          successMessage: 'تم تسجيل حضور اللاعب',
        ));
        if (state.selectedTournament != null) {
          loadParticipants(state.selectedTournament!.id);
        }
      },
    );
  }

  Future<void> drawBracket(String tournamentId) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await repository.drawBracket(tournamentId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentCubitStatus.failure,
        errorMessage: failure.message,
      )),
      (matchesList) {
        emit(state.copyWith(
          status: TournamentCubitStatus.actionSuccess,
          matches: matchesList,
          successMessage: 'تمت إقامة القرعة وتوليد الشجرة بنجاح',
        ));
        loadTournaments();
      },
    );
  }

  Future<void> loadMatches(String tournamentId) async {
    final result = await repository.getMatches(tournamentId);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (list) {
        final disputed = list.where((m) => m.isDisputed).toList();
        emit(state.copyWith(matches: list, disputedMatches: disputed));
      },
    );
  }

  Future<void> startMatch(String matchId, {String? roomId}) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await repository.startMatch(matchId, roomId: roomId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentCubitStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          status: TournamentCubitStatus.actionSuccess,
          successMessage: 'تم بدء المباراة',
        ));
        if (state.selectedTournament != null) {
          loadMatches(state.selectedTournament!.id);
        }
      },
    );
  }

  Future<void> resolveDispute(
    String matchId, {
    required String winnerId,
    required int p1Score,
    required int p2Score,
    required String resolutionNotes,
  }) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await repository.resolveDispute(
      matchId,
      winnerId: winnerId,
      p1Score: p1Score,
      p2Score: p2Score,
      resolutionNotes: resolutionNotes,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentCubitStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          status: TournamentCubitStatus.actionSuccess,
          successMessage: 'تم حل النزاع وتحديد الفائز بنجاح',
        ));
        if (state.selectedTournament != null) {
          loadMatches(state.selectedTournament!.id);
          loadAuditLogs(state.selectedTournament!.id);
        }
      },
    );
  }

  Future<void> completeTournament(String tournamentId) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await repository.completeTournament(tournamentId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentCubitStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          status: TournamentCubitStatus.actionSuccess,
          successMessage: 'تم إنهاء البطولة بنجاح',
        ));
        loadTournaments();
      },
    );
  }

  Future<void> awardPrizes(String tournamentId) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await repository.awardPrizes(tournamentId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentCubitStatus.failure,
        errorMessage: failure.message,
      )),
      (data) {
        emit(state.copyWith(
          status: TournamentCubitStatus.actionSuccess,
          lastAwardResult: data,
          successMessage: 'تم توزيع الجوائز ونقاط XP للمستحقين بنجاح',
        ));
        loadAuditLogs(tournamentId);
      },
    );
  }

  Future<void> loadAuditLogs(String tournamentId, {int page = 1, int pageSize = 50}) async {
    final result = await repository.getTournamentAuditLogsPage(
      tournamentId: tournamentId,
      page: page,
      pageSize: pageSize,
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (paginated) => emit(state.copyWith(
        auditLogs: paginated.items,
        auditLogsPage: paginated.page,
        auditLogsPageSize: paginated.pageSize,
        totalAuditLogsCount: paginated.totalCount,
      )),
    );
  }

  void startWatchingDisputes(String tournamentId) {
    _disputesSubscription?.cancel();
    _disputesSubscription = repository.watchDisputedMatches(tournamentId).listen((disputedList) {
      emit(state.copyWith(disputedMatches: disputedList));
    });
  }

  @override
  Future<void> close() {
    _disputesSubscription?.cancel();
    return super.close();
  }
}
