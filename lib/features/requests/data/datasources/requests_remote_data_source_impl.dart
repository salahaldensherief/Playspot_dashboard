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
            if (status == RealtimeSubscribeStatus.subscribed) {
              // Guarantee recovery of missed events upon connection establish or reconnect
              fetchAndEmit();
            } else if (status == RealtimeSubscribeStatus.channelError) {
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
          try {
            realtimeChannel?.unsubscribe();
            client.removeChannel(realtimeChannel!);
          } catch (e) {
            debugPrint('⚠️ [REQUESTS_DATA_SOURCE] Error removing channel: $e');
          }
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
  Future<void> markRequestAsAttended(
    String id, {
    bool isCanteenOrder = false,
  }) async {
    final uuidRegExp = RegExp(
      r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
    );
    final match = uuidRegExp.firstMatch(id);
    if (match == null) {
      throw ArgumentError.value(id, 'id', 'Request id must contain a UUID');
    }

    if (id.startsWith('ext_')) {
      if (_locallyAttendedIds.length > 300) {
        _locallyAttendedIds.clear();
      }
      _locallyAttendedIds.add(id);
      return;
    }

    if (id.startsWith('item_')) {
      // booking_items are no longer a canonical live-request source.
      if (_locallyAttendedIds.length > 300) {
        _locallyAttendedIds.clear();
      }
      _locallyAttendedIds.add(id);
      return;
    }

    final requestType = switch (id) {
      final value when value.startsWith('canteen_') => 'canteen_order',
      final value when value.startsWith('sc_') => 'service_call',
      final value when value.startsWith('req_') => 'client_request',
      _ when isCanteenOrder => 'canteen_order',
      _ => throw ArgumentError.value(
          id,
          'id',
          'Unsupported live-request identifier',
        ),
    };

    await client.rpc(
      'resolve_live_request',
      params: {
        'p_request_type': requestType,
        'p_request_id': match.group(0)!,
      },
    );

    if (_locallyAttendedIds.length > 300) {
      _locallyAttendedIds.clear();
    }
    _locallyAttendedIds.add(id);
  }

}
