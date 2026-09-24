import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import 'package:play_spot_dashboard/core/utils/realtime_watcher_mixin.dart';
import 'package:play_spot_dashboard/features/requests/domain/entities/client_request_entity.dart';
import '../../../core/audio/audio_service.dart';
import '../domain/usecases/get_active_lounge_requests_page_usecase.dart';
import '../domain/usecases/mark_request_as_attended_usecase.dart';
import '../domain/usecases/watch_client_requests_usecase.dart';
import 'client_requests_state.dart';

class ClientRequestsCubit extends Cubit<ClientRequestsState> with RealtimeWatcherMixin<ClientRequestsState> {
  final WatchClientRequestsUseCase _watchClientRequestsUseCase;
  final MarkRequestAsAttendedUseCase _markRequestAsAttendedUseCase;
  final GetActiveLoungeRequestsPageUseCase _getActiveLoungeRequestsPageUseCase;
  final AudioService audioService;

  final Set<String> _knownRequestIds = {};
  bool _isFirstLoad = true;

  ClientRequestsCubit({
    required WatchClientRequestsUseCase watchClientRequestsUseCase,
    required MarkRequestAsAttendedUseCase markRequestAsAttendedUseCase,
    required GetActiveLoungeRequestsPageUseCase getActiveLoungeRequestsPageUseCase,
    required this.audioService,
  })  : _watchClientRequestsUseCase = watchClientRequestsUseCase,
        _markRequestAsAttendedUseCase = markRequestAsAttendedUseCase,
        _getActiveLoungeRequestsPageUseCase = getActiveLoungeRequestsPageUseCase,
        super(const ClientRequestsState());

  void startWatchingRequests({String? loungeId, bool forceRefresh = false}) {
    final cleanLoungeId = (loungeId != null && loungeId.trim().isNotEmpty) ? loungeId.trim() : null;
    if (cleanLoungeId == null) return;

    if (isAlreadyWatching(cleanLoungeId, forceRefresh: forceRefresh)) {
      return;
    }

    _isFirstLoad = true;
    _knownRequestIds.clear();

    emit(state.copyWith(status: ClientRequestsStatus.loading));

    startWatch<List<dynamic>>(
      entityId: cleanLoungeId,
      stream: _watchClientRequestsUseCase(loungeId: cleanLoungeId),
      onData: (requestsList) {
        final requests = requestsList.cast<dynamic>();
        final currentUnattendedIds = requests
            .where((r) => !(r.isAttended as bool))
            .map((r) => r.id as String)
            .toSet();

        if (_isFirstLoad) {
          _isFirstLoad = false;
          _knownRequestIds.addAll(currentUnattendedIds);
        } else {
          final newIds = currentUnattendedIds.difference(_knownRequestIds);
          if (newIds.isNotEmpty) {
            _knownRequestIds.addAll(newIds);
            for (final id in newIds) {
              final newReqList = requests.where((r) => (r as ClientRequestEntity).id == id);
              if (newReqList.isNotEmpty) {
                final newReq = newReqList.first as ClientRequestEntity;
                try {
                  if (newReq.type == ClientRequestType.canteenOrder) {
                    audioService.playCanteenOrderSound();
                  } else if (newReq.type == ClientRequestType.callStaff ||
                      newReq.type == ClientRequestType.serviceRequest) {
                    audioService.playServiceCallSound();
                  } else {
                    audioService.playReceiptVerificationSound();
                  }
                } catch (e) {
                  AppLogger.warning('Audio notification play failed: $e');
                }
              }
            }
          }
        }

        if (currentUnattendedIds.isEmpty) {
          audioService.stopUrgentAlertSound();
        }

        emit(state.copyWith(
          status: ClientRequestsStatus.success,
          requests: requests.cast(),
        ));
      },
      onError: (error) {
        emit(state.copyWith(
          status: ClientRequestsStatus.failure,
          errorMessage: error.toString(),
        ));
      },
    );
  }

  void setFilter(RequestFilter filter) {
    emit(state.copyWith(filter: filter, page: 1));
  }

  Future<void> fetchActiveRequestsPage({
    required String loungeId,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (loungeId.isEmpty) return;
    emit(state.copyWith(status: ClientRequestsStatus.loading));

    final result = await _getActiveLoungeRequestsPageUseCase(
      GetActiveLoungeRequestsPageParams(
        loungeId: loungeId,
        page: page,
        pageSize: pageSize,
      ),
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: ClientRequestsStatus.failure,
        errorMessage: failure.message,
      )),
      (paginated) => emit(state.copyWith(
        status: ClientRequestsStatus.success,
        requests: paginated.items,
        page: paginated.page,
        pageSize: paginated.pageSize,
        totalCount: paginated.totalCount,
      )),
    );
  }

  Future<void> markAsAttended(String requestId, {bool isCanteenOrder = false}) async {
    if (requestId.isEmpty || requestId.startsWith('notif_')) {
      AppLogger.debug('⚠️ [CUBIT] Skipped backend call for invalid/mock request ID: $requestId');

      final updatedList = state.requests.map((r) {
        if (r.id == requestId) {
          return r.copyWith(isAttended: true, isRead: true);
        }
        return r;
      }).toList();

      emit(state.copyWith(requests: updatedList));

      if (updatedList.where((r) => !r.isAttended).isEmpty) {
        audioService.stopUrgentAlertSound();
      }
      return;
    }

    final originalList = List<ClientRequestEntity>.from(state.requests);

    final updatedList = state.requests.map((r) {
      if (r.id == requestId) {
        return r.copyWith(isAttended: true, isRead: true);
      }
      return r;
    }).toList();

    emit(state.copyWith(requests: updatedList));

    if (updatedList.where((r) => !r.isAttended).isEmpty) {
      audioService.stopUrgentAlertSound();
    }

    final result = await _markRequestAsAttendedUseCase(
      MarkRequestAttendedParams(
        requestId: requestId,
        isCanteenOrder: isCanteenOrder,
      ),
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        AppLogger.warning('🔴 [CUBIT] Mark Attended Failed: ${failure.message}');
        emit(state.copyWith(
          status: ClientRequestsStatus.failure,
          errorMessage: failure.message,
          requests: originalList,
        ));
      },
      (_) => AppLogger.info('🟢 [CUBIT] Request $requestId marked as attended in DB'),
    );
  }
}
