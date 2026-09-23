import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:play_spot_dashboard/core/utils/paginated_result.dart';
import 'package:play_spot_dashboard/features/requests/data/datasources/requests_fallback_fetcher.dart';
import 'package:play_spot_dashboard/features/requests/data/datasources/requests_remote_data_source.dart';
import 'package:play_spot_dashboard/features/requests/data/models/client_request_model.dart';
import 'package:play_spot_dashboard/features/requests/data/models/client_request_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RequestsRemoteDataSourceImpl implements RequestsRemoteDataSource {
  final SupabaseClient client;
  final Set<String> _locallyAttendedIds = {};
  late final RequestsFallbackFetcher _fallbackFetcher;

  RequestsRemoteDataSourceImpl(this.client) {
    _fallbackFetcher = RequestsFallbackFetcher(client);
  }

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
              .onPostgresChanges(
                event: PostgresChangeEvent.all,
                schema: 'public',
                table: 'bookings',
                filter: PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'lounge_id',
                  value: cleanLoungeId,
                ),
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

  @override
  Future<PaginatedResult<ClientRequestModel>> getActiveLoungeRequestsPage({
    required String loungeId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final cleanLoungeId = loungeId.trim();
    if (cleanLoungeId.isEmpty) {
      return PaginatedResult.empty();
    }

    try {
      List<ClientRequestModel> requestsList = [];
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
          mapper: (map) => ClientRequestParser.parseDynamicMap(map),
          requestedPage: page,
          requestedPageSize: pageSize,
        );
        requestsList.addAll(paginated.items);
      } catch (e) {
        debugPrint('⚠️ [REQUESTS_DATA_SOURCE] get_active_lounge_requests_page Error: $e');
      }

      final extensionRequests = await _fallbackFetcher.fetchPendingExtensionRequests(cleanLoungeId);
      final fallbackRequests = await _fallbackFetcher.fetchFallbackRequests(cleanLoungeId);

      final Map<String, ClientRequestModel> uniqueMap = {};
      for (var req in requestsList) {
        uniqueMap[req.id] = req;
      }
      for (var req in extensionRequests) {
        uniqueMap[req.id] = req;
      }
      for (var req in fallbackRequests) {
        uniqueMap[req.id] = req;
      }

      final filteredItems =
          uniqueMap.values.where((m) => !_locallyAttendedIds.contains(m.id)).toList();

      filteredItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return PaginatedResult(
        items: filteredItems,
        totalCount: filteredItems.length,
        page: page,
        pageSize: pageSize,
      );
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
      List<ClientRequestModel> requestsList = [];
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
          mapper: (map) => ClientRequestParser.parseDynamicMap(map),
          requestedPage: 1,
          requestedPageSize: 50,
        );
        requestsList.addAll(paginated.items);
      } catch (e) {
        debugPrint('⚠️ [REQUESTS_DATA_SOURCE] get_active_lounge_requests Error: $e');
      }

      final extensionRequests = await _fallbackFetcher.fetchPendingExtensionRequests(cleanLoungeId);
      final fallbackRequests = await _fallbackFetcher.fetchFallbackRequests(cleanLoungeId);

      final Map<String, ClientRequestModel> uniqueMap = {};
      for (var req in requestsList) {
        uniqueMap[req.id] = req;
      }
      for (var req in extensionRequests) {
        uniqueMap[req.id] = req;
      }
      for (var req in fallbackRequests) {
        uniqueMap[req.id] = req;
      }

      final list =
          uniqueMap.values.where((m) => !_locallyAttendedIds.contains(m.id)).toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint('⚠️ [REQUESTS_DATA_SOURCE] get_active_lounge_requests Error: $e');
      return await _fallbackFetcher.fetchFallbackRequests(cleanLoungeId);
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

    if (rawDbId.isEmpty || rawDbId.startsWith('req_')) {
      debugPrint('⚠️ [REQUESTS_DATA_SOURCE] Skipped DB update for local/temporary ID: $id');
      return;
    }

    try {
      if (id.startsWith('ext_')) {
        await client.from('bookings').update({'extension_status': 'approved'}).eq('id', rawDbId);
        return;
      } else if (id.startsWith('canteen_') || isCanteenOrder) {
        await client.from('canteen_orders').update({'status': 'completed'}).eq('id', rawDbId);
        try {
          final canteenOrder = await client
              .from('canteen_orders')
              .select('booking_id')
              .eq('id', rawDbId)
              .maybeSingle();
          if (canteenOrder != null && canteenOrder['booking_id'] != null) {
            await client
                .from('service_calls')
                .update({'status': 'completed', 'is_attended': true})
                .eq('booking_id', canteenOrder['booking_id'])
                .eq('call_type', 'canteen_order');
          }
        } catch (_) {}
        return;
      } else if (id.startsWith('item_')) {
        await client
            .from('booking_items')
            .update({'status': 'completed', 'is_attended': true, 'is_read': true})
            .eq('id', rawDbId);
        return;
      } else if (id.startsWith('sc_')) {
        await client
            .from('service_calls')
            .update({'status': 'resolved', 'is_attended': true, 'is_read': true})
            .eq('id', rawDbId);
        return;
      }

      final tables = ['service_calls', 'client_requests', 'canteen_orders', 'booking_items', 'bookings'];
      for (final table in tables) {
        try {
          Map<String, dynamic> updatePayload;
          if (table == 'bookings') {
            updatePayload = {'extension_status': 'approved'};
          } else if (table == 'canteen_orders') {
            updatePayload = {'status': 'completed'};
          } else if (table == 'booking_items') {
            updatePayload = {'status': 'completed', 'is_attended': true, 'is_read': true};
          } else {
            updatePayload = {'status': 'resolved', 'is_attended': true, 'is_read': true};
          }

          final response = await client.from(table).update(updatePayload).eq('id', rawDbId).select();
          if ((response as List).isNotEmpty) {
            debugPrint('🟢 [REQUESTS_DATA_SOURCE] Marked request $id as attended in table $table');
            return;
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('⚠️ [REQUESTS_DATA_SOURCE] markRequestAsAttended Error for $id: $e');
    }
  }
}
