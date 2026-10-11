import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/utils/paginated_result.dart';
import 'package:play_spot_dashboard/core/streams/refreshing_stream.dart';

import '../models/lounge_review_model.dart';

abstract class ReviewsRemoteDataSource {
  /// Real-time stream of reviews for a lounge filtered by loungeId.
  Stream<List<LoungeReviewModel>> watchLoungeReviews({
    required String loungeId,
  });

  /// Single fetch of reviews for a lounge.
  Future<List<LoungeReviewModel>> getLoungeReviews({required String loungeId});

  /// Paginated fetch of reviews for a lounge.
  Future<PaginatedResult<LoungeReviewModel>> getLoungeReviewsPage({
    required String loungeId,
    int page = 1,
    int pageSize = 20,
  });
}

class ReviewsRemoteDataSourceImpl implements ReviewsRemoteDataSource {
  final SupabaseClient supabaseClient;

  ReviewsRemoteDataSourceImpl(this.supabaseClient);

  Future<List<LoungeReviewModel>> _resolveReviewProfiles(
    List<Map<String, dynamic>> rawList,
  ) async {
    if (rawList.isEmpty) return [];

    final userIds = rawList
        .map((json) => (json['user_id'] ?? json['userId'])?.toString())
        .where((id) => id != null && id.trim().isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    final profilesMap = <String, Map<String, dynamic>>{};
    if (userIds.isNotEmpty) {
      try {
        final profilesResponse = await supabaseClient.rpc(
          'get_lounge_review_authors',
          params: {'p_lounge_id': rawList.first['lounge_id']},
        );

        for (final profile in profilesResponse as List) {
          final data = Map<String, dynamic>.from(profile as Map);
          final id = data['user_id']?.toString();
          if (id != null && userIds.contains(id)) profilesMap[id] = data;
        }
      } catch (e) {
        debugPrint('[REVIEWS_DATA_SOURCE] Profiles batch fetch failed: $e');
      }
    }

    return rawList.map((json) {
      final profile =
          profilesMap[(json['user_id'] ?? json['userId'])?.toString()];
      if (profile != null) {
        json['profiles'] = profile;
        if (json['user_name'] == null ||
            json['user_name'].toString().trim().isEmpty) {
          json['user_name'] = profile['full_name'];
        }
        if (json['user_avatar'] == null ||
            json['user_avatar'].toString().trim().isEmpty) {
          json['user_avatar'] = profile['avatar_url'];
        }
      }
      return LoungeReviewModel.fromJson(json);
    }).toList();
  }

  Future<List<LoungeReviewModel>> _fetchReviewsFromSupabase(
    String loungeId,
  ) async {
    try {
      // 1. Fetch reviews directly from lounge_reviews table
      final response = await supabaseClient
          .from('lounge_reviews')
          .select()
          .eq('lounge_id', loungeId)
          .order('created_at', ascending: false);

      final rawList = (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      return await _resolveReviewProfiles(rawList);
    } catch (e) {
      debugPrint('🔴 [REVIEWS_DATA_SOURCE] Fetching reviews failed: $e');
      rethrow;
    }
  }

  @override
  Stream<List<LoungeReviewModel>> watchLoungeReviews({
    required String loungeId,
  }) {
    if (loungeId.isEmpty) {
      debugPrint(
        '⚠️ [REVIEWS_DATA_SOURCE] watchLoungeReviews called with empty loungeId',
      );
      return Stream.value([]);
    }

    return refreshingStream<List<LoungeReviewModel>>(
      fetch: () => _fetchReviewsFromSupabase(loungeId),
      invalidations: () => supabaseClient
          .from('lounge_reviews')
          .stream(primaryKey: ['id'])
          .eq('lounge_id', loungeId),
      pollInterval: const Duration(seconds: 10),
      onRealtimeError: (error) =>
          debugPrint('[REVIEWS_DATA_SOURCE] Realtime unavailable: $error'),
    );
  }

  @override
  Future<List<LoungeReviewModel>> getLoungeReviews({
    required String loungeId,
  }) async {
    if (loungeId.isEmpty) return [];
    return _fetchReviewsFromSupabase(loungeId);
  }

  @override
  Future<PaginatedResult<LoungeReviewModel>> getLoungeReviewsPage({
    required String loungeId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final cleanLoungeId = loungeId.trim();
    if (cleanLoungeId.isEmpty) {
      return PaginatedResult.empty(
        requestedPage: page,
        requestedPageSize: pageSize,
      );
    }

    final clampedPageSize = pageSize.clamp(1, 100);
    final validPage = page < 1 ? 1 : page;

    try {
      final response = await supabaseClient.rpc(
        'get_lounge_reviews_page',
        params: {
          'p_lounge_id': cleanLoungeId,
          'p_page': validPage,
          'p_page_size': clampedPageSize,
        },
      );

      final paginated = PaginatedResult.fromRpcResponse<Map<String, dynamic>>(
        response,
        mapper: (json) => json,
        requestedPage: validPage,
        requestedPageSize: clampedPageSize,
      );
      final reviews = await _resolveReviewProfiles(paginated.items);
      return PaginatedResult<LoungeReviewModel>(
        items: reviews,
        totalCount: paginated.totalCount,
        page: paginated.page,
        pageSize: paginated.pageSize,
      );
    } catch (e) {
      debugPrint(
        '⚠️ [REVIEWS_DATA_SOURCE] get_lounge_reviews_page RPC error ($e), falling back',
      );
      final fallbackList = await getLoungeReviews(loungeId: cleanLoungeId);
      final start = (validPage - 1) * clampedPageSize;
      return PaginatedResult(
        items: start >= fallbackList.length
            ? <LoungeReviewModel>[]
            : fallbackList.skip(start).take(clampedPageSize).toList(),
        totalCount: fallbackList.length,
        page: validPage,
        pageSize: clampedPageSize,
      );
    }
  }
}
