import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/services/location_service.dart';
import 'package:play_spot_dashboard/core/services/storage_service.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import 'package:play_spot_dashboard/core/utils/optimistic_update_extension.dart';
import '../domain/entities/tournament_entity.dart';
import '../domain/entities/tournament_match_entity.dart';
import '../domain/entities/tournament_participant_entity.dart';
import '../domain/entities/tournament_prize_entity.dart';
import '../domain/usecases/tournament_match_usecases.dart';
import '../domain/usecases/tournament_participant_usecases.dart';
import '../domain/usecases/tournament_usecases.dart';
import 'tournament_state.dart';

class TournamentCubit extends Cubit<TournamentState> {
  final GetTournamentsUseCase _getTournamentsUseCase;
  final CreateTournamentUseCase _createTournamentUseCase;
  final UpdateTournamentUseCase _updateTournamentUseCase;
  final SaveTournamentPrizesUseCase _saveTournamentPrizesUseCase;
  final PublishTournamentUseCase _publishTournamentUseCase;
  final CancelTournamentUseCase _cancelTournamentUseCase;
  final DeleteDraftTournamentUseCase _deleteDraftTournamentUseCase;
  final DeleteTournamentUseCase _deleteTournamentUseCase;
  final CompleteTournamentUseCase _completeTournamentUseCase;
  final AwardPrizesUseCase _awardPrizesUseCase;
  final GetTournamentAuditLogsUseCase _getTournamentAuditLogsUseCase;
  final WatchDisputedMatchesUseCase _watchDisputedMatchesUseCase;
  final GetTournamentParticipantsUseCase _getParticipantsUseCase;
  final ApproveParticipantPaymentUseCase _approvePaymentUseCase;
  final RejectParticipantPaymentUseCase _rejectPaymentUseCase;
  final RecordCashPaymentUseCase _recordCashPaymentUseCase;
  final PromoteWaitlistUseCase _promoteWaitlistUseCase;
  final CheckInParticipantUseCase _checkInParticipantUseCase;
  final WithdrawParticipantUseCase _withdrawParticipantUseCase;
  final DrawBracketUseCase _drawBracketUseCase;
  final GetTournamentMatchesUseCase _getMatchesUseCase;
  final StartMatchUseCase _startMatchUseCase;
  final ResolveDisputeUseCase _resolveDisputeUseCase;
  final LocationService locationService;
  final StorageService storageService;

  StreamSubscription<List<TournamentMatchEntity>>? _disputesSubscription;

  TournamentCubit({
    required GetTournamentsUseCase getTournamentsUseCase,
    required CreateTournamentUseCase createTournamentUseCase,
    required UpdateTournamentUseCase updateTournamentUseCase,
    required SaveTournamentPrizesUseCase saveTournamentPrizesUseCase,
    required PublishTournamentUseCase publishTournamentUseCase,
    required CancelTournamentUseCase cancelTournamentUseCase,
    required DeleteDraftTournamentUseCase deleteDraftTournamentUseCase,
    required DeleteTournamentUseCase deleteTournamentUseCase,
    required CompleteTournamentUseCase completeTournamentUseCase,
    required AwardPrizesUseCase awardPrizesUseCase,
    required GetTournamentAuditLogsUseCase getTournamentAuditLogsUseCase,
    required WatchDisputedMatchesUseCase watchDisputedMatchesUseCase,
    required GetTournamentParticipantsUseCase getParticipantsUseCase,
    required ApproveParticipantPaymentUseCase approvePaymentUseCase,
    required RejectParticipantPaymentUseCase rejectPaymentUseCase,
    required RecordCashPaymentUseCase recordCashPaymentUseCase,
    required PromoteWaitlistUseCase promoteWaitlistUseCase,
    required CheckInParticipantUseCase checkInParticipantUseCase,
    required WithdrawParticipantUseCase withdrawParticipantUseCase,
    required DrawBracketUseCase drawBracketUseCase,
    required GetTournamentMatchesUseCase getMatchesUseCase,
    required StartMatchUseCase startMatchUseCase,
    required ResolveDisputeUseCase resolveDisputeUseCase,
    required this.locationService,
    required this.storageService,
  })  : _getTournamentsUseCase = getTournamentsUseCase,
        _createTournamentUseCase = createTournamentUseCase,
        _updateTournamentUseCase = updateTournamentUseCase,
        _saveTournamentPrizesUseCase = saveTournamentPrizesUseCase,
        _publishTournamentUseCase = publishTournamentUseCase,
        _cancelTournamentUseCase = cancelTournamentUseCase,
        _deleteDraftTournamentUseCase = deleteDraftTournamentUseCase,
        _deleteTournamentUseCase = deleteTournamentUseCase,
        _completeTournamentUseCase = completeTournamentUseCase,
        _awardPrizesUseCase = awardPrizesUseCase,
        _getTournamentAuditLogsUseCase = getTournamentAuditLogsUseCase,
        _watchDisputedMatchesUseCase = watchDisputedMatchesUseCase,
        _getParticipantsUseCase = getParticipantsUseCase,
        _approvePaymentUseCase = approvePaymentUseCase,
        _rejectPaymentUseCase = rejectPaymentUseCase,
        _recordCashPaymentUseCase = recordCashPaymentUseCase,
        _promoteWaitlistUseCase = promoteWaitlistUseCase,
        _checkInParticipantUseCase = checkInParticipantUseCase,
        _withdrawParticipantUseCase = withdrawParticipantUseCase,
        _drawBracketUseCase = drawBracketUseCase,
        _getMatchesUseCase = getMatchesUseCase,
        _startMatchUseCase = startMatchUseCase,
        _resolveDisputeUseCase = resolveDisputeUseCase,
        super(const TournamentState());

  @override
  void emit(TournamentState state) {
    if (isClosed) return;
    super.emit(state);
  }

  void setTab(int index) {
    emit(state.copyWith(selectedTab: index));
  }

  Future<void> loadTournaments({
    String? loungeId,
    String? status,
    bool requestLocation = true,
  }) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));

    double? userLat;
    double? userLng;

    if (requestLocation) {
      try {
        final position = await locationService.getCurrentPosition();
        if (position != null) {
          userLat = position.latitude;
          userLng = position.longitude;
        }
      } catch (e) {
        AppLogger.warning('Location request error: $e');
      }
    }

    final result = await _getTournamentsUseCase(GetTournamentsParams(
      loungeId: loungeId,
      status: status,
      latitude: userLat,
      longitude: userLng,
    ));

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

  Future<bool> createTournament(
    TournamentEntity tournament, {
    Uint8List? bannerBytes,
    String? bannerName,
  }) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));

    TournamentEntity tournamentToCreate = tournament;

    if (bannerBytes != null && bannerName != null) {
      try {
        final bannerUrl = await storageService.uploadTournamentBanner(
          bannerBytes,
          bannerName,
          tournament.id,
        );
        tournamentToCreate = tournament.copyWith(bannerUrl: bannerUrl);
      } catch (e) {
        AppLogger.error('Banner upload failed: $e');
        final cleanMsg = e.toString().replaceFirst('Exception: ', '');
        emit(state.copyWith(
          status: TournamentCubitStatus.failure,
          errorMessage: cleanMsg,
        ));
        return false;
      }
    }

    final result = await _createTournamentUseCase(tournamentToCreate);

    return result.fold(
      (failure) {
        emit(state.copyWith(
          status: TournamentCubitStatus.failure,
          errorMessage: failure.message,
        ));
        return false;
      },
      (created) {
        final updatedList = [created, ...state.tournaments];
        emit(state.copyWith(
          status: TournamentCubitStatus.actionSuccess,
          tournaments: updatedList,
          selectedTournament: created,
          successMessage: 'تم إنشاء البطولة بنجاح',
        ));
        _refreshSelectedTournamentData(created.id);
        return true;
      },
    );
  }

  Future<bool> updateTournament(
    TournamentEntity tournament, {
    Uint8List? bannerBytes,
    String? bannerName,
  }) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));

    TournamentEntity tournamentToUpdate = tournament;

    if (bannerBytes != null && bannerName != null) {
      try {
        final bannerUrl = await storageService.uploadTournamentBanner(
          bannerBytes,
          bannerName,
          tournament.id,
        );
        tournamentToUpdate = tournament.copyWith(bannerUrl: bannerUrl);
      } catch (e) {
        AppLogger.error('Banner upload failed: $e');
        final cleanMsg = e.toString().replaceFirst('Exception: ', '');
        emit(state.copyWith(
          status: TournamentCubitStatus.failure,
          errorMessage: cleanMsg,
        ));
        return false;
      }
    }

    final result = await _updateTournamentUseCase(tournamentToUpdate);

    return result.fold(
      (failure) {
        emit(state.copyWith(
          status: TournamentCubitStatus.failure,
          errorMessage: failure.message,
        ));
        return false;
      },
      (updated) {
        final list = state.tournaments.map((t) => t.id == updated.id ? updated : t).toList();
        emit(state.copyWith(
          status: TournamentCubitStatus.actionSuccess,
          tournaments: list,
          selectedTournament: updated,
          successMessage: 'تم تحديث بيانات البطولة بنجاح',
        ));
        return true;
      },
    );
  }

  Future<void> saveTournamentPrizes(String tournamentId, List<TournamentPrizeEntity> prizes) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await _saveTournamentPrizesUseCase(
      SaveTournamentPrizesParams(tournamentId: tournamentId, prizes: prizes),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentCubitStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          status: TournamentCubitStatus.actionSuccess,
          successMessage: 'تم حفظ جوائز البطولة بنجاح',
        ));
      },
    );
  }

  Future<void> publishTournament(String tournamentId) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await _publishTournamentUseCase(tournamentId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentCubitStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        final updatedList = state.tournaments.map((t) {
          if (t.id == tournamentId) {
            return t.copyWith(status: TournamentStatus.published);
          }
          return t;
        }).toList();
        final updatedSelected = state.selectedTournament?.id == tournamentId
            ? state.selectedTournament?.copyWith(status: TournamentStatus.published)
            : state.selectedTournament;

        emit(state.copyWith(
          status: TournamentCubitStatus.actionSuccess,
          tournaments: updatedList,
          selectedTournament: updatedSelected,
          successMessage: 'تم نشر البطولة بنجاح',
        ));
      },
    );
  }

  Future<void> cancelTournament(String tournamentId, String reason) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await _cancelTournamentUseCase(
      CancelTournamentParams(tournamentId: tournamentId, reason: reason),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentCubitStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        final updatedList = state.tournaments.map((t) {
          if (t.id == tournamentId) {
            return t.copyWith(status: TournamentStatus.cancelled);
          }
          return t;
        }).toList();
        final updatedSelected = state.selectedTournament?.id == tournamentId
            ? state.selectedTournament?.copyWith(status: TournamentStatus.cancelled)
            : state.selectedTournament;

        emit(state.copyWith(
          status: TournamentCubitStatus.actionSuccess,
          tournaments: updatedList,
          selectedTournament: updatedSelected,
          successMessage: 'تم إلغاء البطولة',
        ));
      },
    );
  }

  Future<void> deleteDraftTournament(String tournamentId) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await _deleteDraftTournamentUseCase(tournamentId);

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

  Future<void> deleteTournament(String tournamentId) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await _deleteTournamentUseCase(tournamentId);

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
          successMessage: 'تم حذف البطولة بنجاح',
        ));
      },
    );
  }

  Future<void> loadParticipants(String tournamentId) async {
    final result = await _getParticipantsUseCase(tournamentId);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (list) => emit(state.copyWith(participants: list)),
    );
  }

  Future<void> approvePayment(String participantId) async {
    final original = List<TournamentParticipantEntity>.from(state.participants);
    await optimisticUpdate<void>(
      apply: (curr) => curr.copyWith(
        status: TournamentCubitStatus.actionSuccess,
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
      rollback: (curr, failure) => curr.copyWith(
        status: TournamentCubitStatus.failure,
        participants: original,
        errorMessage: failure.message,
      ),
    );
  }

  Future<void> rejectPayment(String participantId, String reason) async {
    final original = List<TournamentParticipantEntity>.from(state.participants);
    await optimisticUpdate<void>(
      apply: (curr) => curr.copyWith(
        status: TournamentCubitStatus.actionSuccess,
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
      rollback: (curr, failure) => curr.copyWith(
        status: TournamentCubitStatus.failure,
        participants: original,
        errorMessage: failure.message,
      ),
    );
  }

  Future<void> recordCashPayment(String participantId) async {
    final original = List<TournamentParticipantEntity>.from(state.participants);
    await optimisticUpdate<void>(
      apply: (curr) => curr.copyWith(
        status: TournamentCubitStatus.actionSuccess,
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
      rollback: (curr, failure) => curr.copyWith(
        status: TournamentCubitStatus.failure,
        participants: original,
        errorMessage: failure.message,
      ),
    );
  }

  Future<void> promoteWaitlist(String tournamentId) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await _promoteWaitlistUseCase(tournamentId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentCubitStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        emit(state.copyWith(
          status: TournamentCubitStatus.actionSuccess,
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
        status: TournamentCubitStatus.actionSuccess,
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
      rollback: (curr, failure) => curr.copyWith(
        status: TournamentCubitStatus.failure,
        participants: original,
        errorMessage: failure.message,
      ),
    );
  }

  Future<void> withdrawParticipant(String participantId) async {
    final original = List<TournamentParticipantEntity>.from(state.participants);
    await optimisticUpdate<void>(
      apply: (curr) => curr.copyWith(
        status: TournamentCubitStatus.actionSuccess,
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
      rollback: (curr, failure) => curr.copyWith(
        status: TournamentCubitStatus.failure,
        participants: original,
        errorMessage: failure.message,
      ),
    );
  }

  Future<void> drawBracket(String tournamentId) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await _drawBracketUseCase(tournamentId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentCubitStatus.failure,
        errorMessage: failure.message,
      )),
      (matchesList) {
        final updatedList = state.tournaments.map((t) {
          if (t.id == tournamentId) {
            return t.copyWith(status: TournamentStatus.inProgress);
          }
          return t;
        }).toList();
        final updatedSelected = state.selectedTournament?.id == tournamentId
            ? state.selectedTournament?.copyWith(status: TournamentStatus.inProgress)
            : state.selectedTournament;

        emit(state.copyWith(
          status: TournamentCubitStatus.actionSuccess,
          tournaments: updatedList,
          selectedTournament: updatedSelected,
          matches: matchesList,
          successMessage: 'تمت إقامة القرعة وتوليد الشجرة بنجاح',
        ));
      },
    );
  }

  Future<void> loadMatches(String tournamentId) async {
    final result = await _getMatchesUseCase(tournamentId);
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
    final result = await _startMatchUseCase(StartMatchParams(matchId: matchId, roomId: roomId));

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
    final result = await _resolveDisputeUseCase(ResolveDisputeParams(
      matchId: matchId,
      winnerId: winnerId,
      p1Score: p1Score,
      p2Score: p2Score,
      resolutionNotes: resolutionNotes,
    ));

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
    final result = await _completeTournamentUseCase(tournamentId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: TournamentCubitStatus.failure,
        errorMessage: failure.message,
      )),
      (_) {
        final updatedList = state.tournaments.map((t) {
          if (t.id == tournamentId) {
            return t.copyWith(status: TournamentStatus.completed);
          }
          return t;
        }).toList();
        final updatedSelected = state.selectedTournament?.id == tournamentId
            ? state.selectedTournament?.copyWith(status: TournamentStatus.completed)
            : state.selectedTournament;

        emit(state.copyWith(
          status: TournamentCubitStatus.actionSuccess,
          tournaments: updatedList,
          selectedTournament: updatedSelected,
          successMessage: 'تم إنهاء البطولة بنجاح',
        ));
      },
    );
  }

  Future<void> awardPrizes(String tournamentId) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await _awardPrizesUseCase(tournamentId);

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
    final result = await _getTournamentAuditLogsUseCase(GetTournamentAuditLogsParams(
      tournamentId: tournamentId,
      page: page,
      pageSize: pageSize,
    ));
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
    _disputesSubscription = _watchDisputedMatchesUseCase(tournamentId).listen((disputedList) {
      emit(state.copyWith(disputedMatches: disputedList));
    });
  }

  @override
  Future<void> close() {
    _disputesSubscription?.cancel();
    return super.close();
  }
}
