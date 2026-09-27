import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/core/utils/paginated_result.dart';
import '../entities/lounge_review_entity.dart';

abstract class ReviewsRepository {
  Stream<List<LoungeReviewEntity>> watchLoungeReviews({required String loungeId});
  Future<Either<Failure, List<LoungeReviewEntity>>> getLoungeReviews({required String loungeId});
  Future<Either<Failure, PaginatedResult<LoungeReviewEntity>>> getLoungeReviewsPage({
    required String loungeId,
    int page = 1,
    int pageSize = 20,
  });
}
