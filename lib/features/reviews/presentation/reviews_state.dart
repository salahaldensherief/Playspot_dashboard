import 'package:equatable/equatable.dart';
import '../domain/entities/lounge_review_entity.dart';

enum ReviewsStatus { initial, loading, success, failure }

class ReviewsState extends Equatable {
  final ReviewsStatus status;
  final List<LoungeReviewEntity> reviews;
  final double averageRating;
  final String? errorMessage;

  const ReviewsState({
    this.status = ReviewsStatus.initial,
    this.reviews = const [],
    this.averageRating = 0.0,
    this.errorMessage,
  });

  ReviewsState copyWith({
    ReviewsStatus? status,
    List<LoungeReviewEntity>? reviews,
    double? averageRating,
    String? errorMessage,
  }) {
    return ReviewsState(
      status: status ?? this.status,
      reviews: reviews ?? this.reviews,
      averageRating: averageRating ?? this.averageRating,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        reviews,
        averageRating,
        errorMessage,
      ];
}
