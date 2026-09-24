import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:play_spot_dashboard/core/utils/app_logger.dart';
import 'package:play_spot_dashboard/features/rooms/data/models/room_model.dart';
import '../models/extra_model.dart';
import '../models/lounge_model.dart';
import 'lounge_analytics_remote_helper.dart';
import 'lounge_extras_remote_helper.dart';
import 'lounge_query_remote_helper.dart';
import 'lounge_remote_data_source.dart';

class LoungeRemoteDataSourceImpl implements LoungeRemoteDataSource {
  final SupabaseClient client;
  late final LoungeQueryRemoteHelper _queryHelper;
  late final LoungeExtrasRemoteHelper _extrasHelper;
  late final LoungeAnalyticsRemoteHelper _analyticsHelper;

  LoungeRemoteDataSourceImpl(this.client) {
    _queryHelper = LoungeQueryRemoteHelper(client);
    _extrasHelper = LoungeExtrasRemoteHelper(client);
    _analyticsHelper = LoungeAnalyticsRemoteHelper(client);
  }

  @override
  Future<List<LoungeModel>> getLounges() => _queryHelper.getLounges();

  @override
  Future<List<LoungeModel>> getOwnerBranches(String ownerId) =>
      _queryHelper.getOwnerBranches(ownerId);

  @override
  Future<Map<String, dynamic>> addLoungeBranch(Map<String, dynamic> branchData) =>
      _queryHelper.addLoungeBranch(branchData);

  @override
  Future<Map<String, dynamic>> getMultiBranchOverview({
    required String ownerId,
    required DateTime startDate,
    required DateTime endDate,
  }) =>
      _queryHelper.getMultiBranchOverview(
        ownerId: ownerId,
        startDate: startDate,
        endDate: endDate,
      );

  @override
  Future<LoungeModel?> getLoungeById(String id) => _queryHelper.getLoungeById(id);

  @override
  Future<Map<String, dynamic>> createLoungeWithOwner({
    required String email,
    required String password,
    required String ownerName,
    required String loungeName,
    String? city,
    String? address,
    String? phone,
  }) =>
      _queryHelper.createLoungeWithOwner(
        email: email,
        password: password,
        ownerName: ownerName,
        loungeName: loungeName,
        city: city,
        address: address,
        phone: phone,
      );

  @override
  Future<void> updateLounge(String id, Map<String, dynamic> data) async {
    final cleanData = Map<String, dynamic>.from(data);
    cleanData.remove('id');
    cleanData.remove('owner_name');
    cleanData.remove('owner_email');
    cleanData.remove('rating');
    cleanData.remove('distance');
    cleanData.remove('price_per_hour');
    cleanData.remove('available_rooms');
    cleanData.remove('total_reviews');
    cleanData.remove('opens_at');
    cleanData.remove('closes_at');
    cleanData.remove('description');
    cleanData.remove('lat');
    cleanData.remove('lng');
    cleanData.remove('latitude');
    cleanData.remove('longitude');

    for (final timeKey in ['opening_time', 'closing_time']) {
      if (cleanData.containsKey(timeKey)) {
        final val = cleanData[timeKey];
        if (val == null || (val is String && val.trim().isEmpty)) {
          cleanData.remove(timeKey);
        }
      }
    }

    cleanData.removeWhere((key, value) => value == null);

    try {
      await client.from('lounges').update(cleanData).eq('id', id);
      AppLogger.info('updateLounge Succeeded for id: $id');
    } on PostgrestException catch (e) {
      AppLogger.error('updateLounge PostgrestException: ${e.message} (code: ${e.code}, details: ${e.details})');
      rethrow;
    } catch (e) {
      AppLogger.error('updateLounge Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateLoungeDiscount(String id, {
    required bool hasDiscount,
    required int discountPercentage,
    String? titleAr,
    String? titleEn,
    DateTime? expiresAt,
    String? vodafoneCashNumber,
    String? instapayAccount,
  }) async {
    final updateData = <String, dynamic>{
      'has_discount': hasDiscount,
      'discount_percentage': hasDiscount ? discountPercentage : 0,
      'discount_title_ar': hasDiscount ? (titleAr ?? '') : '',
      'discount_title_en': hasDiscount ? (titleEn ?? '') : '',
      'discount_expires_at': hasDiscount ? expiresAt?.toIso8601String() : null,
      if (vodafoneCashNumber != null && vodafoneCashNumber.trim().isNotEmpty)
        'vodafone_cash_number': vodafoneCashNumber.trim(),
      if (instapayAccount != null && instapayAccount.trim().isNotEmpty)
        'instapay_account': instapayAccount.trim(),
    };

    try {
      await client.from('lounges').update(updateData).eq('id', id);
      AppLogger.info('updateLoungeDiscount Succeeded for id: $id');
    } on PostgrestException catch (e) {
      AppLogger.error('updateLoungeDiscount PostgrestException: ${e.message} (code: ${e.code})');
      rethrow;
    } catch (e) {
      AppLogger.error('updateLoungeDiscount Error: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getDashboardStats(String? loungeId) =>
      _analyticsHelper.getDashboardStats(loungeId);

  @override
  Future<Map<String, dynamic>> getDashboardOverview() =>
      _analyticsHelper.getDashboardOverview();

  @override
  Future<List<Map<String, dynamic>>> getRevenueOverTime(int daysBack) =>
      _analyticsHelper.getRevenueOverTime(daysBack);

  @override
  Future<List<Map<String, dynamic>>> getTopLoungesByRevenue(int limitCount) =>
      _analyticsHelper.getTopLoungesByRevenue(limitCount);

  @override
  Future<List<RoomModel>> getRooms(String loungeId) async {
    final response = await client
        .from('rooms')
        .select('*')
        .eq('lounge_id', loungeId)
        .order('created_at', ascending: true);
    return (response as List).map((json) => RoomModel.fromJson(json)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getActivities(String roomId) async {
    final response = await client
        .from('room_activities')
        .select('*, activity_types(*)')
        .eq('room_id', roomId);
    return (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Future<List<ExtraModel>> getExtras(String loungeId) =>
      _extrasHelper.getExtras(loungeId);

  @override
  Future<void> addExtra(ExtraModel extra) => _extrasHelper.addExtra(extra);

  @override
  Future<void> updateExtra(ExtraModel extra) => _extrasHelper.updateExtra(extra);

  @override
  Future<void> deleteExtra(String extraId) => _extrasHelper.deleteExtra(extraId);

  @override
  Future<void> toggleExtraStock(String extraId, bool isOutOfStock) =>
      _extrasHelper.toggleExtraStock(extraId, isOutOfStock);

  @override
  Future<void> toggleLoungeOpenStatus(String loungeId, bool isOpen) async {
    try {
      if (isOpen) {
        await client.rpc('open_lounge_shift', params: {
          'p_lounge_id': loungeId,
          'p_starting_cash': 0,
          'p_notes': null,
        });
      } else {
        await client.rpc('close_lounge_shift', params: {
          'p_lounge_id': loungeId,
          'p_actual_cash_counted': 0,
          'p_notes': 'Closed via Lounge Toggle',
        });
      }
      AppLogger.info('toggleLoungeOpenStatus RPC Succeeded for loungeId: $loungeId, isOpen: $isOpen');
    } catch (e) {
      AppLogger.warning('toggleLoungeOpenStatus RPC failed ($e), falling back to direct table update...');
      try {
        await client.from('lounges').update({'is_open': isOpen}).eq('id', loungeId);
        AppLogger.info('toggleLoungeOpenStatus direct update succeeded for loungeId: $loungeId, isOpen: $isOpen');
      } on PostgrestException catch (pe) {
        AppLogger.error('toggleLoungeOpenStatus PostgrestException: ${pe.message} (code: ${pe.code})');
        rethrow;
      } catch (e2) {
        AppLogger.error('toggleLoungeOpenStatus Error: $e2');
        rethrow;
      }
    }
  }

  @override
  Future<String> createLounge(LoungeModel lounge) async {
    final data = lounge.toJson();
    data.remove('id');
    data.remove('opens_at');
    data.remove('closes_at');
    data.remove('description');

    final response = await client.from('lounges').insert(data).select('id').single();
    return response['id'].toString();
  }

  @override
  Future<void> createLoungeAdmin({
    required String email,
    required String password,
    required String name,
    required String loungeId,
  }) async {
    await client.rpc('create_lounge_admin', params: {
      'p_email': email,
      'p_password': password,
      'p_full_name': name,
      'p_lounge_id': loungeId,
    });
  }

  @override
  Future<void> deleteLounge(String id) => _queryHelper.deleteLounge(id);
}
