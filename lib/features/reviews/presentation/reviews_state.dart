import 'package:equatable/equatable.dart';
import '../domain/entities/lounge_review_entity.dart';

enum ReviewsStatus { initial, loading, success, failure }

class ReviewsState extends Equatable {
  final ReviewsStatus status;
  final List<LoungeReviewEntity> reviews;
  final double averageRating;
  final int page;
  final int pageSize;
  final int totalCount;
  final String? errorMessage;

  const ReviewsState({
    this.status = ReviewsStatus.initial,
    this.reviews = const [],
    this.averageRating = 0.0,
    this.page = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.errorMessage,
  });

  bool get hasNextPage => page * pageSize < totalCount;
  bool get hasPreviousPage => page > 1;
  int get totalPages => pageSize > 0 ? (totalCount / pageSize).ceil() : 0;

  ReviewsState copyWith({
    ReviewsStatus? status,
    List<LoungeReviewEntity>? reviews,
    double? averageRating,
    int? page,
    int? pageSize,
    int? totalCount,
    String? errorMessage,
  }) {
    return ReviewsState(
      status: status ?? this.status,
      reviews: reviews ?? this.reviews,
      averageRating: averageRating ?? this.averageRating,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        reviews,
        averageRating,
        page,
        pageSize,
        totalCount,
        errorMessage,
      ];
}
