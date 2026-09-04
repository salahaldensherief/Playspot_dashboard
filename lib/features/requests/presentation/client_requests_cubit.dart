import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/audio/audio_service.dart';
import '../domain/repositories/client_requests_repository.dart';
import 'client_requests_state.dart';

class ClientRequestsCubit extends Cubit<ClientRequestsState> {
  final ClientRequestsRepository repository;
  final AudioService audioService;
  StreamSubscription? _subscription;

  final Set<String> _knownRequestIds = {};
  bool _isFirstLoad = true;
  String? _watchedLoungeId;

  ClientRequestsCubit({
    required this.repository,
    required this.audioService,
  }) : super(const ClientRequestsState());

  void startWatchingRequests({required String loungeId}) {
    if (loungeId.isEmpty) return;

    if (_subscription != null && _watchedLoungeId == loungeId) {
      return;
    }

    _watchedLoungeId = loungeId;
    _isFirstLoad = true;
    _knownRequestIds.clear();

    emit(state.copyWith(status: ClientRequestsStatus.loading));
    _subscription?.cancel();

    _subscription = repository.watchClientRequests(loungeId: loungeId).listen(
      (requests) {
        if (isClosed) return;

        final currentUnattendedIds = requests
            .where((r) => !r.isAttended)
            .map((r) => r.id)
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
          requests: requests,
        ));
      },
      onError: (error) {
        if (isClosed) return;
        emit(state.copyWith(
          status: ClientRequestsStatus.failure,
          errorMessage: error.toString(),
        ));
      },
    );
  }

  void setFilter(RequestFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  Future<void> markAsAttended(String requestId, {bool isCanteenOrder = false}) async {
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
        ));
      },
      (_) => debugPrint('🟢 [CUBIT] Request $requestId marked as attended in DB'),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
