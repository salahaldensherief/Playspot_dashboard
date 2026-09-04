import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/reviews/domain/entities/lounge_review_entity.dart';
import 'package:play_spot_dashboard/features/reviews/domain/repositories/reviews_repository.dart';
import 'package:play_spot_dashboard/features/reviews/domain/usecases/watch_lounge_reviews_usecase.dart';
import 'package:play_spot_dashboard/features/reviews/presentation/reviews_cubit.dart';
import 'package:play_spot_dashboard/features/reviews/presentation/reviews_state.dart';

class FakeReviewsRepository implements ReviewsRepository {
  List<LoungeReviewEntity> reviewsToEmit = [];

  @override
  Stream<List<LoungeReviewEntity>> watchLoungeReviews({required String loungeId}) {
    return Stream.value(reviewsToEmit);
  }

  @override
  Future<Either<Failure, List<LoungeReviewEntity>>> getLoungeReviews({required String loungeId}) async {
    return Right(reviewsToEmit);
  }
}

void main() {
  group('ReviewsCubit Unit Tests', () {
    late FakeReviewsRepository repository;
    late ReviewsCubit cubit;

    setUp(() {
      repository = FakeReviewsRepository();
      cubit = ReviewsCubit(
        watchLoungeReviewsUseCase: WatchLoungeReviewsUseCase(repository),
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('Initial state should be ReviewsStatus.initial', () {
      expect(cubit.state.status, ReviewsStatus.initial);
      expect(cubit.state.reviews, isEmpty);
      expect(cubit.state.averageRating, 0.0);
    });

    test('startWatchingReviews calculates average rating accurately', () async {
      repository.reviewsToEmit = [
        LoungeReviewEntity(
          id: 'r1',
          loungeId: 'l1',
          rating: 5.0,
          comment: 'Great lounge!',
          createdAt: DateTime.now(),
        ),
        LoungeReviewEntity(
          id: 'r2',
          loungeId: 'l1',
          rating: 4.0,
          comment: 'Nice equipment',
          createdAt: DateTime.now(),
        ),
      ];

      cubit.startWatchingReviews(loungeId: 'l1');

      await Future.delayed(Duration.zero);

      expect(cubit.state.status, ReviewsStatus.success);
      expect(cubit.state.reviews.length, 2);
      expect(cubit.state.averageRating, 4.5);
    });
  });
}
