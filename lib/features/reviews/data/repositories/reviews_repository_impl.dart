import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../../domain/entities/lounge_review_entity.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../datasources/reviews_remote_data_source.dart';

class ReviewsRepositoryImpl implements ReviewsRepository {
  final ReviewsRemoteDataSource remoteDataSource;

  ReviewsRepositoryImpl(this.remoteDataSource);

  @override
  Stream<List<LoungeReviewEntity>> watchLoungeReviews({required String loungeId}) {
    return remoteDataSource.watchLoungeReviews(loungeId: loungeId);
  }

  @override
  Future<Either<Failure, List<LoungeReviewEntity>>> getLoungeReviews({required String loungeId}) async {
    try {
      final reviews = await remoteDataSource.getLoungeReviews(loungeId: loungeId);
      return Right(reviews);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
