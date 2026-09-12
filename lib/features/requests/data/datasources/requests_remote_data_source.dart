import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/paginated_result.dart';
import '../models/client_request_model.dart';

abstract class RequestsRemoteDataSource {
  Stream<List<ClientRequestModel>> watchClientRequests({required String loungeId});
  Future<List<ClientRequestModel>> getClientRequests({required String loungeId});
  Future<PaginatedResult<ClientRequestModel>> getActiveLoungeRequestsPage({
    required String loungeId,
    int page = 1,
    int pageSize = 20,
  });
  Future<void> markRequestAsAttended(String id, {bool isCanteenOrder = false});
}

class RequestsRemoteDataSourceImpl implements RequestsRemoteDataSource {
  final SupabaseClient client;
  final Set<String> _locallyAttendedIds = {};

  RequestsRemoteDataSourceImpl(this.client);

  @override
  Stream<List<ClientRequestModel>> watchClientRequests({required String loungeId}) {
    final cleanLoungeId = loungeId.trim();
    if (cleanLoungeId.isEmpty) {
      return Stream.value([]);
    }

    late StreamController<List<ClientRequestModel>> controller;
    RealtimeChannel? realtimeChannel;
    Timer? backupSyncTimer;
    Timer? debounceTimer;
    bool isFetching = false;

    void fetchAndEmit() {
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 300), () async {
        if (isFetching) return;
        isFetching = true;
        try {
          final requests = await getClientRequests(loungeId: cleanLoungeId);
          if (!controller.isClosed) {
            controller.add(requests);
          }
        } catch (e) {
          debugPrint('⚠️ [REQUESTS_DATA_SOURCE] fetchAndEmit Error: $e');
        } finally {
          isFetching = false;
        }
      });
    }

    controller = StreamController<List<ClientRequestModel>>(
      onListen: () {
        fetchAndEmit();

        try {
          final channelName = 'lounge_requests_channel_$cleanLoungeId';
          realtimeChannel = client.channel(channelName);

          realtimeChannel!
              .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'service_calls',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'lounge_id',
              value: cleanLoungeId,
            ),
            callback: (_) => fetchAndEmit(),
          )
              .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'canteen_orders',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'lounge_id',
              value: cleanLoungeId,
            ),
            callback: (_) => fetchAndEmit(),
          )
              .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'client_requests',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'lounge_id',
              value: cleanLoungeId,
            ),
            callback: (_) => fetchAndEmit(),
          )
              .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'booking_items',
            callback: (_) => fetchAndEmit(),
          )
              .subscribe((status, error) {
            if (status == RealtimeSubscribeStatus.channelError) {
              debugPrint('⚠️ [REQUESTS_DATA_SOURCE] Realtime Channel Error: $error');
            }
          });
        } catch (e) {
          debugPrint('⚠️ [REQUESTS_DATA_SOURCE] Realtime setup failed: $e');
        }

        backupSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
          fetchAndEmit();
        });
      },
      onCancel: () {
        debounceTimer?.cancel();
        backupSyncTimer?.cancel();
        if (realtimeChannel != null) {
          client.removeChannel(realtimeChannel!);
          realtimeChannel = null;
        }
      },
    );

    return controller.stream;
  }

  ClientRequestModel _parseClientRequestMap(Map<String, dynamic> map) {
    if (map['id'] == null || map['id'].toString().trim().isEmpty) {
      map['id'] = map['request_id'] ?? map['booking_id'] ?? 'req_${DateTime.now().microsecondsSinceEpoch}';
    }

    final typeStr = (map['type'] ?? map['request_type'] ?? '').toString().toLowerCase();

    if (typeStr.contains('canteen') || typeStr.contains('order')) {
      return ClientRequestModel.fromCanteenOrderJson(map);
    } else if (typeStr.contains('extend') || typeStr.contains('extension')) {
      return ClientRequestModel.fromBookingExtensionJson(map);
    } else if (typeStr.contains('staff') || typeStr.contains('call') || typeStr.contains('assistance')) {
      return ClientRequestModel.fromServiceCallJson(map);
    } else {
      return ClientRequestModel.fromNotificationJson(map);
    }
  }

  @override
  Future<PaginatedResult<ClientRequestModel>> getActiveLoungeRequestsPage({
    required String loungeId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final cleanLoungeId = loungeId.trim();
    if (cleanLoungeId.isEmpty) {
      return PaginatedResult.empty(requestedPage: page, requestedPageSize: pageSize);
    }

    try {
      final response = await client.rpc(
        'get_active_lounge_requests_page',
        params: {
          'p_lounge_id': cleanLoungeId,
          'p_page': page,
          'p_page_size': pageSize,
        },
      );

      final paginated = PaginatedResult.fromRpcResponse<ClientRequestModel>(
        response,
        mapper: (map) => _parseClientRequestMap(map),
        requestedPage: page,
        requestedPageSize: pageSize,
      );

      final filteredItems = paginated.items
          .where((m) => !_locallyAttendedIds.contains(m.id))
          .toList();

      return paginated.copyWith(items: filteredItems);
    } catch (e) {
      debugPrint('⚠️ [REQUESTS_DATA_SOURCE] get_active_lounge_requests_page Error: $e');
      final fallbackList = await getClientRequests(loungeId: cleanLoungeId);
      return PaginatedResult(
        items: fallbackList,
        totalCount: fallbackList.length,
        page: page,
        pageSize: pageSize,
      );
    }
  }

  @override
  Future<List<ClientRequestModel>> getClientRequests({required String loungeId}) async {
    final cleanLoungeId = loungeId.trim();
    if (cleanLoungeId.isEmpty) return [];

    try {
      final response = await client.rpc(
        'get_active_lounge_requests_page',
        params: {
          'p_lounge_id': cleanLoungeId,
          'p_page': 1,
          'p_page_size': 50,
        },
      );

      final paginated = PaginatedResult.fromRpcResponse<ClientRequestModel>(
        response,
        mapper: (map) => _parseClientRequestMap(map),
        requestedPage: 1,
        requestedPageSize: 50,
      );

      final list = paginated.items
          .where((m) => !_locallyAttendedIds.contains(m.id))
          .toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint('⚠️ [REQUESTS_DATA_SOURCE] get_active_lounge_requests Error: $e');
      return [];
    }
  }

  @override
  Future<void> markRequestAsAttended(String id, {bool isCanteenOrder = false}) async {
    _locallyAttendedIds.add(id);

    final String rawDbId = id
        .replaceFirst('canteen_', '')
        .replaceFirst('notif_', '')
        .replaceFirst('sc_', '')
        .replaceFirst('item_', '')
        .replaceFirst('req_', '')
        .replaceFirst('ext_', '');

    // إذا كان الـ ID مؤقت أو غير صالح للداتا بيز، نتخطى الاتصال بالسيرفر لمنع أخطاء الـ UUID
    if (rawDbId.isEmpty || rawDbId.startsWith('req_')) {
      debugPrint('⚠️ [REQUESTS_DATA_SOURCE] Skipped DB update for local/temporary ID: $id');
      return;
    }

    try {
      if (id.startsWith('sc_')) {
        await client.from('service_calls').update({
          'status': 'resolved',
          'is_attended': true,
          'is_read': true,
        }).eq('id', rawDbId);
      } else if (id.startsWith('canteen_') || isCanteenOrder) {
        await client.from('canteen_orders').update({
          'status': 'completed',
          'is_attended': true,
          'is_read': true,
        }).eq('id', rawDbId);
      } else if (id.startsWith('item_')) {
        await client.from('booking_items').update({
          'status': 'completed',
          'is_attended': true,
          'is_read': true,
        }).eq('id', rawDbId);
      } else if (id.startsWith('req_')) {
        await client.from('client_requests').update({
          'status': 'resolved',
          'is_attended': true,
          'is_read': true,
        }).eq('id', rawDbId);
      } else if (id.startsWith('ext_')) {
        await client.from('bookings').update({
          'extension_status': 'approved',
        }).eq('id', rawDbId);
      } else {
        await client.from('notifications').update({
          'is_read': true,
          'is_attended': true,
        }).eq('id', rawDbId);
      }
      debugPrint('🟢 [REQUESTS_DATA_SOURCE] Successfully marked request $id as attended');
    } catch (e) {
      debugPrint('⚠️ [REQUESTS_DATA_SOURCE] markRequestAsAttended Error for $id: $e');
    }
  }
}