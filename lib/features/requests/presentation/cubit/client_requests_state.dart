import 'package:equatable/equatable.dart';
import '../../domain/entities/client_request_entity.dart';

enum ClientRequestsStatus { initial, loading, success, failure }

enum RequestFilter { all, callStaff, canteenOrders, unattendedOnly }

class ClientRequestsState extends Equatable {
  final ClientRequestsStatus status;
  final List<ClientRequestEntity> requests;
  final RequestFilter filter;
  final String? errorMessage;

  const ClientRequestsState({
    this.status = ClientRequestsStatus.initial,
    this.requests = const [],
    this.filter = RequestFilter.all,
    this.errorMessage,
  });

  List<ClientRequestEntity> get filteredRequests {
    switch (filter) {
      case RequestFilter.callStaff:
        return requests.where((r) => r.type == ClientRequestType.callStaff).toList();
      case RequestFilter.canteenOrders:
        return requests.where((r) => r.isCanteenOrder).toList();
      case RequestFilter.unattendedOnly:
        return requests.where((r) => !r.isAttended).toList();
      case RequestFilter.all:
      default:
        return requests;
    }
  }

  int get unreadCount => requests.where((r) => !r.isAttended).length;

  ClientRequestsState copyWith({
    ClientRequestsStatus? status,
    List<ClientRequestEntity>? requests,
    RequestFilter? filter,
    String? errorMessage,
  }) {
    return ClientRequestsState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      filter: filter ?? this.filter,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, requests, filter, errorMessage];
}
