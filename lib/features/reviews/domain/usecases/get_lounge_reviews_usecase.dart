import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../../domain/entities/lounge_review_entity.dart';
import '../../domain/repositories/reviews_repository.dart';

class GetLoungeReviewsUseCase {
  final ReviewsRepository repository;

  GetLoungeReviewsUseCase(this.repository);

  Future<Either<Failure, List<LoungeReviewEntity>>> call({required String loungeId}) {
    return repository.getLoungeReviews(loungeId: loungeId);
  }
}
