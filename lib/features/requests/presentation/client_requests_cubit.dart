import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/utils/realtime_watcher_mixin.dart';
import 'package:play_spot_dashboard/features/requests/domain/entities/client_request_entity.dart';
import '../../../core/audio/audio_service.dart';
import '../domain/repositories/client_requests_repository.dart';
import 'client_requests_state.dart';

class ClientRequestsCubit extends Cubit<ClientRequestsState> with RealtimeWatcherMixin<ClientRequestsState> {
  final ClientRequestsRepository repository;
  final AudioService audioService;

  final Set<String> _knownRequestIds = {};
  bool _isFirstLoad = true;

  ClientRequestsCubit({
    required this.repository,
    required this.audioService,
  }) : super(const ClientRequestsState());

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
      stream: repository.watchClientRequests(loungeId: cleanLoungeId),
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
            try {
              audioService.playNotificationSound();
            } catch (e) {
              debugPrint('Audio notification play failed: $e');
            }
          }
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

    final result = await repository.getActiveLoungeRequestsPage(
      loungeId: loungeId,
      page: page,
      pageSize: pageSize,
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
      debugPrint('⚠️ [CUBIT] Skipped backend call for invalid/mock request ID: $requestId');

      final updatedList = state.requests.map((r) {
        if (r.id == requestId) {
          return r.copyWith(isAttended: true, isRead: true);
        }
        return r;
      }).toList();

      emit(state.copyWith(requests: updatedList));
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

    final result = await repository.markRequestAsAttended(
      requestId,
      isCanteenOrder: isCanteenOrder,
    );

    if (isClosed) return;

    result.fold(
      (failure) {
        debugPrint('🔴 [CUBIT] Mark Attended Failed: ${failure.message}');
        emit(state.copyWith(
          status: ClientRequestsStatus.failure,
          errorMessage: failure.message,
          requests: originalList,
        ));
      },
      (_) => debugPrint('🟢 [CUBIT] Request $requestId marked as attended in DB'),
    );
  }
}
