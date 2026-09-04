import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/entities/lounge_review_entity.dart';
import '../domain/usecases/watch_lounge_reviews_usecase.dart';
import 'reviews_state.dart';

class ReviewsCubit extends Cubit<ReviewsState> {
  final WatchLoungeReviewsUseCase watchLoungeReviewsUseCase;
  StreamSubscription<List<LoungeReviewEntity>>? _subscription;
  String? _watchedLoungeId;

  ReviewsCubit({
    required this.watchLoungeReviewsUseCase,
  }) : super(const ReviewsState());

  void startWatchingReviews({required String loungeId}) {
    final cleanLoungeId = loungeId.trim();
    if (cleanLoungeId.isEmpty) return;

    if (_subscription != null && _watchedLoungeId == cleanLoungeId) {
      return;
    }

    _watchedLoungeId = cleanLoungeId;
    _subscription?.cancel();

    emit(state.copyWith(status: ReviewsStatus.loading));

    _subscription = watchLoungeReviewsUseCase(loungeId: cleanLoungeId).listen(
      (reviews) {
        if (isClosed) return;

        double totalRating = 0.0;
        for (final r in reviews) {
          totalRating += r.rating;
        }

        final double avgRating = reviews.isNotEmpty
            ? (totalRating / reviews.length)
            : 0.0;

        emit(state.copyWith(
          status: ReviewsStatus.success,
          reviews: reviews,
          averageRating: double.parse(avgRating.toStringAsFixed(1)),
        ));
      },
      onError: (error) {
        if (isClosed) return;
        debugPrint('🔴 [REVIEWS_CUBIT] Stream Error: $error');
        emit(state.copyWith(
          status: ReviewsStatus.failure,
          errorMessage: error.toString(),
        ));
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
