import '../../domain/entities/lounge_review_entity.dart';
import '../../domain/repositories/reviews_repository.dart';

class WatchLoungeReviewsUseCase {
  final ReviewsRepository repository;

  WatchLoungeReviewsUseCase(this.repository);

  Stream<List<LoungeReviewEntity>> call({required String loungeId}) {
    return repository.watchLoungeReviews(loungeId: loungeId);
  }
}
