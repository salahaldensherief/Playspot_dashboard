import 'package:equatable/equatable.dart';
import '../domain/entities/client_request_entity.dart';

enum ClientRequestsStatus { initial, loading, success, failure }

enum RequestFilter { all, callStaff, canteenOrders, extensionRequests, unattendedOnly }

class ClientRequestsState extends Equatable {
  final ClientRequestsStatus status;
  final List<ClientRequestEntity> requests;
  final RequestFilter filter;
  final int page;
  final int pageSize;
  final int totalCount;
  final String? errorMessage;

  const ClientRequestsState({
    this.status = ClientRequestsStatus.initial,
    this.requests = const [],
    this.filter = RequestFilter.all,
    this.page = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.errorMessage,
  });

  int get unreadCount => requests.where((r) => !r.isAttended || !r.isRead).length;

  int get totalPages => pageSize > 0 ? (totalCount / pageSize).ceil() : 0;
  bool get hasNextPage => page * pageSize < totalCount;
  bool get hasPreviousPage => page > 1;

  List<ClientRequestEntity> get filteredRequests {
    final activeRequests = requests.where((r) => !r.isAttended).toList();
    switch (filter) {
      case RequestFilter.callStaff:
        return activeRequests.where((r) => r.type == ClientRequestType.callStaff).toList();
      case RequestFilter.canteenOrders:
        return activeRequests.where((r) => r.isCanteenOrder || r.type == ClientRequestType.canteenOrder).toList();
      case RequestFilter.extensionRequests:
        return activeRequests.where((r) => r.type == ClientRequestType.extendSession).toList();
      case RequestFilter.unattendedOnly:
        return activeRequests;
      case RequestFilter.all:
        return activeRequests;
    }
  }

  ClientRequestsState copyWith({
    ClientRequestsStatus? status,
    List<ClientRequestEntity>? requests,
    RequestFilter? filter,
    int? page,
    int? pageSize,
    int? totalCount,
    String? errorMessage,
  }) {
    return ClientRequestsState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      filter: filter ?? this.filter,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, requests, filter, page, pageSize, totalCount, errorMessage];
}
