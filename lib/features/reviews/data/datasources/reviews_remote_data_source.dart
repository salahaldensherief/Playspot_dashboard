import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lounge_review_model.dart';

abstract class ReviewsRemoteDataSource {
  /// Real-time stream of reviews for a lounge filtered by loungeId.
  Stream<List<LoungeReviewModel>> watchLoungeReviews({required String loungeId});

  /// Single fetch of reviews for a lounge.
  Future<List<LoungeReviewModel>> getLoungeReviews({required String loungeId});
}

class ReviewsRemoteDataSourceImpl implements ReviewsRemoteDataSource {
  final SupabaseClient supabaseClient;

  ReviewsRemoteDataSourceImpl(this.supabaseClient);

  @override
  Stream<List<LoungeReviewModel>> watchLoungeReviews({required String loungeId}) {
    if (loungeId.isEmpty) {
      return Stream.value([]);
    }

    late StreamController<List<LoungeReviewModel>> controller;
    Timer? heartbeatTimer;
    StreamSubscription? postgresSubscription;

    void fetchAndEmit() async {
      try {
        final response = await supabaseClient
            .from('lounge_reviews')
            .select('*, profiles(full_name, email, avatar_url)')
            .eq('lounge_id', loungeId)
            .order('created_at', ascending: false);

        final list = (response as List)
            .map((json) => LoungeReviewModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();

        if (!controller.isClosed) {
          controller.add(list);
        }
      } catch (e) {
        if (!controller.isClosed) {
          try {
            final fallbackResponse = await supabaseClient
                .from('lounge_reviews')
                .select()
                .eq('lounge_id', loungeId)
                .order('created_at', ascending: false);

            final list = (fallbackResponse as List)
                .map((json) => LoungeReviewModel.fromJson(Map<String, dynamic>.from(json)))
                .toList();

            controller.add(list);
          } catch (e2) {
            debugPrint('🔴 [REVIEWS_DATA_SOURCE] fetchAndEmit Fallback Error: $e2');
            controller.addError(e2);
          }
        }
      }
    }

    controller = StreamController<List<LoungeReviewModel>>(
      onListen: () {
        fetchAndEmit();

        try {
          postgresSubscription = supabaseClient
              .from('lounge_reviews')
              .stream(primaryKey: ['id'])
              .eq('lounge_id', loungeId)
              .listen((_) {
                fetchAndEmit();
              }, onError: (e) {
                debugPrint('⚠️ [REVIEWS_DATA_SOURCE] Realtime Stream Error: $e');
              });
        } catch (e) {
          debugPrint('⚠️ [REVIEWS_DATA_SOURCE] Realtime Listen Exception: $e');
        }

        heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          fetchAndEmit();
        });
      },
      onCancel: () {
        postgresSubscription?.cancel();
        heartbeatTimer?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<List<LoungeReviewModel>> getLoungeReviews({required String loungeId}) async {
    if (loungeId.isEmpty) return [];

    try {
      final response = await supabaseClient
          .from('lounge_reviews')
          .select('*, profiles(full_name, email, avatar_url)')
          .eq('lounge_id', loungeId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => LoungeReviewModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      debugPrint('⚠️ [REVIEWS_DATA_SOURCE] getLoungeReviews fallback: $e');
      final fallbackResponse = await supabaseClient
          .from('lounge_reviews')
          .select()
          .eq('lounge_id', loungeId)
          .order('created_at', ascending: false);

      return (fallbackResponse as List)
          .map((json) => LoungeReviewModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
  }
}
