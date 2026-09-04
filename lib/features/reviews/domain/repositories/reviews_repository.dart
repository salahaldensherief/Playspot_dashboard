import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../entities/lounge_review_entity.dart';

abstract class ReviewsRepository {
  Stream<List<LoungeReviewEntity>> watchLoungeReviews({required String loungeId});
  Future<Either<Failure, List<LoungeReviewEntity>>> getLoungeReviews({required String loungeId});
}
