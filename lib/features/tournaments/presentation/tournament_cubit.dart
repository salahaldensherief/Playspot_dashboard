import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/services/location_service.dart';
import 'package:play_spot_dashboard/core/services/storage_service.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import '../domain/entities/tournament_entity.dart';
import '../domain/entities/tournament_prize_entity.dart';
import '../domain/usecases/tournament_usecases.dart';
import 'tournament_audit_manager.dart';
import 'tournament_banner_uploader.dart';
import 'tournament_state_mutator.dart';
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
  final LocationService locationService;
  final TournamentBannerUploader _bannerUploader;
  final TournamentAuditManager _auditManager;

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
    required this.locationService,
    required StorageService storageService,
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
        _bannerUploader = TournamentBannerUploader(storageService),
        _auditManager = TournamentAuditManager(
          getTournamentAuditLogsUseCase: getTournamentAuditLogsUseCase,
          watchDisputedMatchesUseCase: watchDisputedMatchesUseCase,
        ),
        super(const TournamentState());

  @override
  void emit(TournamentState state) {
    if (isClosed) return;
    super.emit(state);
  }

  void setTab(int index) => emit(state.copyWith(selectedTab: index));

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
          currentSelected = list.where((t) => t.id == currentSelected?.id).firstOrNull ?? currentSelected;
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
    loadAuditLogs(tournamentId);
    startWatchingDisputes(tournamentId);
  }

  Future<bool> createTournament(
    TournamentEntity tournament, {
    Uint8List? bannerBytes,
    String? bannerName,
  }) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));

    TournamentEntity entity = tournament;
    try {
      final bannerUrl = await _bannerUploader.upload(
        bytes: bannerBytes,
        name: bannerName,
        tournamentId: tournament.id,
      );
      if (bannerUrl != null) {
        entity = entity.copyWith(bannerUrl: bannerUrl);
      }
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(status: TournamentCubitStatus.failure, errorMessage: cleanMsg));
      return false;
    }

    final result = await _createTournamentUseCase(entity);
    return result.fold(
      (failure) {
        emit(state.copyWith(status: TournamentCubitStatus.failure, errorMessage: failure.message));
        return false;
      },
      (created) {
        emit(state.copyWith(
          status: TournamentCubitStatus.actionSuccess,
          tournaments: [created, ...state.tournaments],
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

    TournamentEntity entity = tournament;
    try {
      final bannerUrl = await _bannerUploader.upload(
        bytes: bannerBytes,
        name: bannerName,
        tournamentId: tournament.id,
      );
      if (bannerUrl != null) {
        entity = entity.copyWith(bannerUrl: bannerUrl);
      }
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(status: TournamentCubitStatus.failure, errorMessage: cleanMsg));
      return false;
    }

    final result = await _updateTournamentUseCase(entity);
    return result.fold(
      (failure) {
        emit(state.copyWith(status: TournamentCubitStatus.failure, errorMessage: failure.message));
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
      (failure) => emit(state.copyWith(status: TournamentCubitStatus.failure, errorMessage: failure.message)),
      (_) => emit(state.copyWith(
        status: TournamentCubitStatus.actionSuccess,
        successMessage: 'تم حفظ جوائز البطولة بنجاح',
      )),
    );
  }

  Future<void> _updateTournamentStatus({
    required String tournamentId,
    required TournamentStatus newStatus,
    required String successMessage,
    required TournamentActionResult Function() action,
  }) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await action();
    result.fold(
      (failure) => emit(TournamentStateMutator.applyFailure(state: state, failure: failure)),
      (_) => emit(TournamentStateMutator.applyStatusUpdate(
        state: state,
        tournamentId: tournamentId,
        newStatus: newStatus,
        successMessage: successMessage,
      )),
    );
  }

  Future<void> publishTournament(String id) => _updateTournamentStatus(
        tournamentId: id,
        newStatus: TournamentStatus.published,
        successMessage: 'تم نشر البطولة بنجاح',
        action: () => _publishTournamentUseCase(id),
      );

  Future<void> cancelTournament(String id, String reason) => _updateTournamentStatus(
        tournamentId: id,
        newStatus: TournamentStatus.cancelled,
        successMessage: 'تم إلغاء البطولة',
        action: () => _cancelTournamentUseCase(CancelTournamentParams(tournamentId: id, reason: reason)),
      );

  Future<void> completeTournament(String id) => _updateTournamentStatus(
        tournamentId: id,
        newStatus: TournamentStatus.completed,
        successMessage: 'تم إنهاء البطولة بنجاح',
        action: () => _completeTournamentUseCase(id),
      );

  Future<void> _deleteHelper({
    required String tournamentId,
    required String successMessage,
    required TournamentActionResult Function() action,
  }) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await action();
    result.fold(
      (failure) => emit(TournamentStateMutator.applyFailure(state: state, failure: failure)),
      (_) => emit(TournamentStateMutator.applyDeletion(
        state: state,
        tournamentId: tournamentId,
        successMessage: successMessage,
      )),
    );
  }

  Future<void> deleteDraftTournament(String id) => _deleteHelper(
        tournamentId: id,
        successMessage: 'تم حذف مسودة البطولة بنجاح',
        action: () => _deleteDraftTournamentUseCase(id),
      );

  Future<void> deleteTournament(String id) => _deleteHelper(
        tournamentId: id,
        successMessage: 'تم حذف البطولة بنجاح',
        action: () => _deleteTournamentUseCase(id),
      );

  Future<void> awardPrizes(String tournamentId) async {
    emit(state.copyWith(status: TournamentCubitStatus.loading));
    final result = await _awardPrizesUseCase(tournamentId);

    result.fold(
      (failure) => emit(state.copyWith(status: TournamentCubitStatus.failure, errorMessage: failure.message)),
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
    final paginated = await _auditManager.loadAuditLogs(tournamentId, page: page, pageSize: pageSize);
    if (paginated != null) {
      emit(state.copyWith(
        auditLogs: paginated.items,
        auditLogsPage: paginated.page,
        auditLogsPageSize: paginated.pageSize,
        totalAuditLogsCount: paginated.totalCount,
      ));
    }
  }

  void startWatchingDisputes(String tournamentId) {
    _auditManager.startWatchingDisputes(tournamentId, (disputedList) {
      emit(state.copyWith(disputedMatches: disputedList));
    });
  }

  @override
  Future<void> close() {
    _auditManager.dispose();
    return super.close();
  }
}
