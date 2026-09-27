import 'package:equatable/equatable.dart';

class PaginatedResult<T> extends Equatable {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  bool get hasNextPage => page * pageSize < totalCount;
  bool get hasPreviousPage => page > 1;
  int get totalPages => pageSize > 0 ? (totalCount / pageSize).ceil() : 0;

  static PaginatedResult<T> empty<T>({int requestedPage = 1, int requestedPageSize = 20}) {
    return PaginatedResult<T>(
      items: const [],
      totalCount: 0,
      page: requestedPage,
      pageSize: requestedPageSize,
    );
  }

  static PaginatedResult<T> fromRpcResponse<T>(
    dynamic response, {
    required T Function(Map<String, dynamic> json) mapper,
    required int requestedPage,
    required int requestedPageSize,
  }) {
    if (response == null || response is! List || response.isEmpty) {
      return PaginatedResult<T>(
        items: const [],
        totalCount: 0,
        page: requestedPage,
        pageSize: requestedPageSize,
      );
    }

    final items = <T>[];

    for (final row in response) {
      if (row is Map) {
        final rowMap = Map<String, dynamic>.from(row);
        final rawData = rowMap['data'];
        final dataMap = rawData != null && rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : rowMap;
        items.add(mapper(dataMap));
      }
    }

    final firstRow = Map<String, dynamic>.from(response.first as Map);
    final totalCount = (firstRow['total_count'] as num?)?.toInt() ?? 0;
    final page = (firstRow['page'] as num?)?.toInt() ?? requestedPage;
    final pageSize = (firstRow['page_size'] as num?)?.toInt() ?? requestedPageSize;

    return PaginatedResult<T>(
      items: items,
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
    );
  }

  PaginatedResult<T> copyWith({
    List<T>? items,
    int? totalCount,
    int? page,
    int? pageSize,
  }) {
    return PaginatedResult<T>(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  List<Object?> get props => [items, totalCount, page, pageSize];
}
