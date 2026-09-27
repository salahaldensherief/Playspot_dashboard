import 'package:equatable/equatable.dart';

/// Standard pagination parameters for list use cases.
/// Per AGENT_RULES §7: queries expected to return > 50 rows must paginate.
class PageParams extends Equatable {
  final int page;
  final int pageSize;

  const PageParams({this.page = 1, this.pageSize = 50});

  int get offset => (page - 1) * pageSize;

  @override
  List<Object?> get props => [page, pageSize];
}
