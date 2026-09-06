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

  Future<List<LoungeReviewModel>> _fetchReviewsFromSupabase(String loungeId) async {
    debugPrint('🔵 [REVIEWS_DATA_SOURCE] Fetching reviews for loungeId: $loungeId');
    try {
      final response = await supabaseClient
          .from('lounge_reviews')
          .select('*, bookings(user_id, user_name, user_phone, profiles(full_name, email, avatar_url)), profiles(full_name, email, avatar_url)')
          .eq('lounge_id', loungeId)
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((json) => LoungeReviewModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      debugPrint('🟢 [REVIEWS_DATA_SOURCE] Fetched ${list.length} reviews via `lounge_reviews` -> `bookings` / `profiles` join');
      return list;
    } catch (e1) {
      debugPrint('⚠️ [REVIEWS_DATA_SOURCE] Primary join query failed ($e1), attempting fallback join on profiles...');
      try {
        final response = await supabaseClient
            .from('lounge_reviews')
            .select('*, profiles(full_name, email, avatar_url)')
            .eq('lounge_id', loungeId)
            .order('created_at', ascending: false);

        final list = (response as List)
            .map((json) => LoungeReviewModel.fromJson(Map<String, dynamic>.from(json)))
            .toList();
        debugPrint('🟢 [REVIEWS_DATA_SOURCE] Fetched ${list.length} reviews from `lounge_reviews` with profiles join');
        return list;
      } catch (e2) {
        debugPrint('⚠️ [REVIEWS_DATA_SOURCE] Profiles join failed ($e2), attempting plain query fallback...');
        try {
          final fallbackResponse = await supabaseClient
              .from('lounge_reviews')
              .select()
              .eq('lounge_id', loungeId)
              .order('created_at', ascending: false);

          final list = (fallbackResponse as List)
              .map((json) => LoungeReviewModel.fromJson(Map<String, dynamic>.from(json)))
              .toList();
          debugPrint('🟢 [REVIEWS_DATA_SOURCE] Fetched ${list.length} reviews from `lounge_reviews` table');
          return list;
        } catch (e3) {
          debugPrint('🔴 [REVIEWS_DATA_SOURCE] All review queries failed: $e3');
          rethrow;
        }
      }
    }
  }

  @override
  Stream<List<LoungeReviewModel>> watchLoungeReviews({required String loungeId}) {
    if (loungeId.isEmpty) {
      debugPrint('⚠️ [REVIEWS_DATA_SOURCE] watchLoungeReviews called with empty loungeId');
      return Stream.value([]);
    }

    late StreamController<List<LoungeReviewModel>> controller;
    Timer? heartbeatTimer;
    StreamSubscription? postgresSubscription;

    void fetchAndEmit() async {
      try {
        final list = await _fetchReviewsFromSupabase(loungeId);
        if (!controller.isClosed) {
          controller.add(list);
        }
      } catch (e) {
        if (!controller.isClosed) {
          debugPrint('🔴 [REVIEWS_DATA_SOURCE] fetchAndEmit Error: $e');
          controller.addError(e);
        }
      }
    }

    controller = StreamController<List<LoungeReviewModel>>(
      onListen: () {
        debugPrint('🚀 [REVIEWS_DATA_SOURCE] Starting real-time stream subscription for lounge: $loungeId');
        fetchAndEmit();

        try {
          postgresSubscription = supabaseClient
              .from('lounge_reviews')
              .stream(primaryKey: ['id'])
              .eq('lounge_id', loungeId)
              .listen((_) {
                debugPrint('🔔 [REVIEWS_DATA_SOURCE] Realtime event received on `lounge_reviews` table');
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
        debugPrint('🛑 [REVIEWS_DATA_SOURCE] Cancelling review stream subscription');
        postgresSubscription?.cancel();
        heartbeatTimer?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<List<LoungeReviewModel>> getLoungeReviews({required String loungeId}) async {
    if (loungeId.isEmpty) return [];
    return _fetchReviewsFromSupabase(loungeId);
  }
}
