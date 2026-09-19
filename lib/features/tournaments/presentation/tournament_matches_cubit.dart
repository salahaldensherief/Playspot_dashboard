import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/utils/realtime_watcher_mixin.dart';
import '../domain/entities/tournament_match_entity.dart';
import '../domain/repositories/tournament_repository.dart';
import 'tournament_matches_state.dart';

class TournamentMatchesCubit extends Cubit<TournamentMatchesState> with RealtimeWatcherMixin<TournamentMatchesState> {
  final TournamentRepository repository;

  TournamentMatchesCubit(this.repository) : super(const TournamentMatchesState());

  Future<void> loadMatches(String tournamentId) async {
    final result = await repository.getMatches(tournamentId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentMatchesStatus.failure,
        errorMessage: failure.message,
      )),
      (list) {
        final disputed = list.where((m) => m.isDisputed).toList();
        emit(state.copyWith(
          status: TournamentMatchesStatus.success,
          matches: list,
          disputedMatches: disputed,
        ));
      },
    );
  }

  void startWatchingDisputes(String tournamentId) {
    if (isAlreadyWatching(tournamentId)) return;

    startWatch<List<TournamentMatchEntity>>(
      entityId: tournamentId,
      stream: repository.watchDisputedMatches(tournamentId),
      onData: (disputedList) {
        final updatedAll = state.matches.map((m) {
          final found = disputedList.firstWhere((d) => d.id == m.id, orElse: () => m);
          return found;
        }).toList();

        emit(state.copyWith(
          matches: updatedAll,
          disputedMatches: disputedList,
        ));
      },
      onError: (e) {
        debugPrint('⚠️ [MATCHES_CUBIT] watchDisputedMatches error: $e');
      },
    );
  }

  Future<void> drawBracket(String tournamentId) async {
    emit(state.copyWith(status: TournamentMatchesStatus.loading));
    final result = await repository.drawBracket(tournamentId);
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentMatchesStatus.failure,
        errorMessage: failure.message,
      )),
      (matchesList) {
        emit(state.copyWith(
          status: TournamentMatchesStatus.actionSuccess,
          matches: matchesList,
          successMessage: 'تمت إقامة القرعة وتوليد الشجرة بنجاح',
        ));
      },
    );
  }

  Future<void> startMatch(String matchId, String tournamentId, {String? roomId}) async {
    emit(state.copyWith(status: TournamentMatchesStatus.loading));
    final result = await repository.startMatch(matchId, roomId: roomId);
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentMatchesStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          status: TournamentMatchesStatus.actionSuccess,
          successMessage: 'تم بدء المباراة',
        ));
        loadMatches(tournamentId);
      },
    );
  }

  Future<void> resolveDispute(
    String matchId,
    String tournamentId, {
    required String winnerId,
    required int p1Score,
    required int p2Score,
    required String resolutionNotes,
  }) async {
    emit(state.copyWith(status: TournamentMatchesStatus.loading));
    final result = await repository.resolveDispute(
      matchId,
      winnerId: winnerId,
      p1Score: p1Score,
      p2Score: p2Score,
      resolutionNotes: resolutionNotes,
    );
    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentMatchesStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          status: TournamentMatchesStatus.actionSuccess,
          successMessage: 'تم حل النزاع وتحديد الفائز بنجاح',
        ));
        loadMatches(tournamentId);
      },
    );
  }
}
