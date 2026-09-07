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
    try {
      // 1. Fetch reviews directly from lounge_reviews table
      final response = await supabaseClient
          .from('lounge_reviews')
          .select()
          .eq('lounge_id', loungeId)
          .order('created_at', ascending: false);

      final rawList = (response as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (rawList.isEmpty) return [];

      // 2. Extract unique user_ids to resolve profiles in a batch
      final userIds = rawList
          .map((json) => json['user_id']?.toString())
          .where((id) => id != null && id.trim().isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      final Map<String, Map<String, dynamic>> profilesMap = {};
      if (userIds.isNotEmpty) {
        try {
          final profilesResponse = await supabaseClient
              .from('profiles')
              .select('id, full_name, email, avatar_url')
              .inFilter('id', userIds);

          for (final p in profilesResponse as List) {
            final pMap = Map<String, dynamic>.from(p as Map);
            final pId = pMap['id']?.toString();
            if (pId != null) {
              profilesMap[pId] = pMap;
            }
          }
        } catch (e) {
          debugPrint('⚠️ [REVIEWS_DATA_SOURCE] Profiles batch fetch failed: $e');
        }
      }

      // 3. Attach profile data to review JSON maps
      final list = rawList.map((json) {
        final uId = json['user_id']?.toString();
        if (uId != null && profilesMap.containsKey(uId)) {
          final p = profilesMap[uId]!;
          json['profiles'] = p;
          if (json['user_name'] == null || json['user_name'].toString().trim().isEmpty) {
            json['user_name'] = p['full_name'];
          }
          if (json['user_avatar'] == null || json['user_avatar'].toString().trim().isEmpty) {
            json['user_avatar'] = p['avatar_url'];
          }
        }
        return LoungeReviewModel.fromJson(json);
      }).toList();

      return list;
    } catch (e) {
      debugPrint('🔴 [REVIEWS_DATA_SOURCE] Fetching reviews failed: $e');
      rethrow;
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

        heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
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
