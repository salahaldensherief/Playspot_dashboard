import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/client_request_entity.dart';
import '../models/client_request_model.dart';

abstract class RequestsRemoteDataSource {
  /// Stream combined real-time notifications, canteen orders, and pending extensions for a lounge.
  Stream<List<ClientRequestModel>> watchClientRequests({required String loungeId});

  /// Fetch combined client requests once for a lounge.
  Future<List<ClientRequestModel>> getClientRequests({required String loungeId});

  /// Mark notification or canteen order as attended / read.
  Future<void> markRequestAsAttended(String id, {bool isCanteenOrder = false});
}

class RequestsRemoteDataSourceImpl implements RequestsRemoteDataSource {
  final SupabaseClient client;

  RequestsRemoteDataSourceImpl(this.client);

  @override
  Stream<List<ClientRequestModel>> watchClientRequests({required String loungeId}) {
    final cleanLoungeId = loungeId.trim();
    if (cleanLoungeId.isEmpty) {
      return Stream.value([]);
    }

    late StreamController<List<ClientRequestModel>> controller;
    Timer? heartbeatTimer;
    StreamSubscription? notifSubscription;
    StreamSubscription? canteenSubscription;
    StreamSubscription? bookingItemsSubscription;
    StreamSubscription? bookingsSubscription;

    void fetchAndEmit() async {
      try {
        final requests = await getClientRequests(loungeId: cleanLoungeId);
        if (!controller.isClosed) {
          controller.add(requests);
        }
      } catch (e) {
        debugPrint('⚠️ [REQUESTS_DATA_SOURCE] fetchAndEmit Error: $e');
      }
    }

    controller = StreamController<List<ClientRequestModel>>(
      onListen: () {
        // 1. Initial fetch & emit
        fetchAndEmit();

        // 2. Realtime Subscriptions for notifications, canteen_orders, and bookings
        // Subscription 1: Notifications stream with graceful fallback on channel error
        try {
          notifSubscription = client
              .from('notifications')
              .stream(primaryKey: ['id'])
              .eq('lounge_id', cleanLoungeId)
              .listen(
                (_) {
                  fetchAndEmit();
                },
                onError: (e) {
                  debugPrint('⚠️ [REQUESTS_DATA_SOURCE] Notifications Realtime Error: $e');
                  if (e is RealtimeSubscribeException) {
                    debugPrint('⚠️ [REQUESTS_DATA_SOURCE] Notifications RealtimeSubscribeException (status: ${e.status}, details: $e)');
                  }
                  _setupNotificationsFallbackStream(cleanLoungeId, fetchAndEmit, (sub) => notifSubscription = sub);
                },
                cancelOnError: false,
              );
        } catch (e) {
          debugPrint('⚠️ [REQUESTS_DATA_SOURCE] Notifications Realtime Exception: $e');
          _setupNotificationsFallbackStream(cleanLoungeId, fetchAndEmit, (sub) => notifSubscription = sub);
        }

        // Subscription 2: Canteen Orders stream
        try {
          canteenSubscription = client
              .from('canteen_orders')
              .stream(primaryKey: ['id'])
              .eq('lounge_id', cleanLoungeId)
              .listen(
                (_) {
                  fetchAndEmit();
                },
                onError: (e) {
                  debugPrint('⚠️ [REQUESTS_DATA_SOURCE] Canteen Realtime Error: $e');
                  if (e is RealtimeSubscribeException) {
                    debugPrint('⚠️ [REQUESTS_DATA_SOURCE] Canteen RealtimeSubscribeException (status: ${e.status}, details: $e)');
                  }
                },
                cancelOnError: false,
              );
        } catch (e) {
          debugPrint('⚠️ [REQUESTS_DATA_SOURCE] Canteen Realtime Exception: $e');
        }

        // Subscription 3: Booking Items stream
        try {
          bookingItemsSubscription = client
              .from('booking_items')
              .stream(primaryKey: ['id'])
              .listen(
                (_) {
                  fetchAndEmit();
                },
                onError: (e) {
                  debugPrint('⚠️ [REQUESTS_DATA_SOURCE] BookingItems Realtime Error: $e');
                },
                cancelOnError: false,
              );
        } catch (e) {
          debugPrint('⚠️ [REQUESTS_DATA_SOURCE] BookingItems Realtime Exception: $e');
        }

        // Subscription 4: Bookings stream
        try {
          bookingsSubscription = client
              .from('bookings')
              .stream(primaryKey: ['id'])
              .eq('lounge_id', cleanLoungeId)
              .listen(
                (_) {
                  fetchAndEmit();
                },
                onError: (e) {
                  debugPrint('⚠️ [REQUESTS_DATA_SOURCE] Bookings Realtime Error: $e');
                  if (e is RealtimeSubscribeException) {
                    debugPrint('⚠️ [REQUESTS_DATA_SOURCE] Bookings RealtimeSubscribeException (status: ${e.status}, details: $e)');
                  }
                },
                cancelOnError: false,
              );
        } catch (e) {
          debugPrint('⚠️ [REQUESTS_DATA_SOURCE] Bookings Realtime Exception: $e');
        }

        // 3. Heartbeat Timer (every 2 seconds) to guarantee immediate real-time updates
        heartbeatTimer = Timer.periodic(const Duration(seconds: 2), (_) {
          fetchAndEmit();
        });
      },
      onCancel: () {
        notifSubscription?.cancel();
        canteenSubscription?.cancel();
        bookingItemsSubscription?.cancel();
        bookingsSubscription?.cancel();
        heartbeatTimer?.cancel();
      },
    );

    return controller.stream;
  }

  void _setupNotificationsFallbackStream(
    String loungeId,
    VoidCallback fetchAndEmit,
    void Function(StreamSubscription) setSubscription,
  ) {
    try {
      debugPrint('🔄 [REQUESTS_DATA_SOURCE] Attempting fallback stream for notifications without filter...');
      final sub = client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .listen(
            (_) {
              fetchAndEmit();
            },
            onError: (e) {
              debugPrint('⚠️ [REQUESTS_DATA_SOURCE] Notifications Fallback Stream Error: $e');
              _setupClientRequestsFallbackStream(loungeId, fetchAndEmit, setSubscription);
            },
            cancelOnError: false,
          );
      setSubscription(sub);
    } catch (e) {
      debugPrint('⚠️ [REQUESTS_DATA_SOURCE] Notifications Fallback Stream Exception: $e');
      _setupClientRequestsFallbackStream(loungeId, fetchAndEmit, setSubscription);
    }
  }

  void _setupClientRequestsFallbackStream(
    String loungeId,
    VoidCallback fetchAndEmit,
    void Function(StreamSubscription) setSubscription,
  ) {
    try {
      debugPrint('🔄 [REQUESTS_DATA_SOURCE] Attempting fallback stream on client_requests table...');
      final sub = client
          .from('client_requests')
          .stream(primaryKey: ['id'])
          .listen(
            (_) {
              fetchAndEmit();
            },
            onError: (e) {
              debugPrint('⚠️ [REQUESTS_DATA_SOURCE] ClientRequests Fallback Stream Error: $e');
            },
            cancelOnError: false,
          );
      setSubscription(sub);
    } catch (e) {
      debugPrint('⚠️ [REQUESTS_DATA_SOURCE] ClientRequests Fallback Stream Exception: $e');
    }
  }

  @override
  Future<List<ClientRequestModel>> getClientRequests({required String loungeId}) async {
    final cleanLoungeId = loungeId.trim();
    if (cleanLoungeId.isEmpty) return [];

    try {
      // 1. Fetch notifications for the active lounge
      dynamic notifResponse = [];
      try {
        notifResponse = await client
            .from('notifications')
            .select()
            .eq('lounge_id', cleanLoungeId)
            .order('created_at', ascending: false)
            .limit(50);
      } catch (e) {
        try {
          notifResponse = await client
              .from('notifications')
              .select()
              .or('lounge_id.eq.$cleanLoungeId,metadata->>lounge_id.eq.$cleanLoungeId')
              .order('created_at', ascending: false)
              .limit(50);
        } catch (_) {
          notifResponse = await client
              .from('notifications')
              .select()
              .order('created_at', ascending: false)
              .limit(50);
        }
      }

      // 1b. Fetch fallback client_requests table if it exists
      dynamic clientReqsResponse = [];
      try {
        clientReqsResponse = await client
            .from('client_requests')
            .select()
            .eq('lounge_id', cleanLoungeId)
            .order('created_at', ascending: false)
            .limit(50);
      } catch (_) {
        // Table client_requests may not exist
      }

      final notifList = [
        ...((notifResponse is List) ? notifResponse : []),
        ...((clientReqsResponse is List) ? clientReqsResponse : []),
      ]
      .map((json) => ClientRequestModel.fromNotificationJson(Map<String, dynamic>.from(json)))
      .where((model) {
        // Strict Lounge ID Filter: Must match active manager lounge_id
        if (cleanLoungeId.isNotEmpty && model.loungeId.isNotEmpty && model.loungeId != cleanLoungeId) {
          return false;
        }

        // Operational Requests Only: Strictly EXCLUDE personal user notification types
        // (like booking acceptances, session starts, or promo announcements)
        if (model.type == ClientRequestType.other) {
          return false;
        }

        return true;
      })
      .toList();

      // 2. Fetch canteen orders for the active lounge
      dynamic ordersResponse = [];
      try {
        ordersResponse = await client
            .from('canteen_orders')
            .select()
            .eq('lounge_id', cleanLoungeId)
            .order('created_at', ascending: false)
            .limit(50);
      } catch (e) {
        try {
          ordersResponse = await client
              .from('canteen_orders')
              .select()
              .order('created_at', ascending: false)
              .limit(50);
        } catch (_) {}
      }

      final ordersList = ((ordersResponse is List) ? ordersResponse : [])
          .map((json) => ClientRequestModel.fromCanteenOrderJson(Map<String, dynamic>.from(json)))
          .where((model) {
            if (cleanLoungeId.isNotEmpty && model.loungeId.isNotEmpty && model.loungeId != cleanLoungeId) {
              return false;
            }
            return true;
          }).toList();

      // 2b. Fetch canteen items from booking_items table
      dynamic bookingItemsResponse = [];
      try {
        bookingItemsResponse = await client
            .from('booking_items')
            .select('*, bookings!inner(id, lounge_id, user_name, room_name, user_id, user_phone)')
            .eq('bookings.lounge_id', cleanLoungeId)
            .order('created_at', ascending: false)
            .limit(50);
      } catch (e) {
        try {
          bookingItemsResponse = await client
              .from('booking_items')
              .select()
              .order('created_at', ascending: false)
              .limit(50);
        } catch (_) {}
      }

      final bookingItemsList = ((bookingItemsResponse is List) ? bookingItemsResponse : [])
          .map((json) => ClientRequestModel.fromBookingItemJson(Map<String, dynamic>.from(json)))
          .where((model) {
            if (cleanLoungeId.isNotEmpty && model.loungeId.isNotEmpty && model.loungeId != cleanLoungeId) {
              return false;
            }
            return true;
          }).toList();

      // 3. Fetch pending session extensions for the active lounge
      dynamic extensionsResponse = [];
      try {
        extensionsResponse = await client
            .from('bookings')
            .select()
            .eq('lounge_id', cleanLoungeId)
            .eq('extension_status', 'pending')
            .order('updated_at', ascending: false)
            .limit(50);
      } catch (e) {
        try {
          extensionsResponse = await client
              .from('bookings')
              .select()
              .eq('extension_status', 'pending')
              .order('updated_at', ascending: false)
              .limit(50);
        } catch (_) {}
      }

      final extensionsList = ((extensionsResponse is List) ? extensionsResponse : [])
          .map((json) => ClientRequestModel.fromBookingExtensionJson(Map<String, dynamic>.from(json)))
          .where((model) {
            if (cleanLoungeId.isNotEmpty && model.loungeId.isNotEmpty && model.loungeId != cleanLoungeId) {
              return false;
            }
            return true;
          }).toList();

      final combined = [...notifList, ...ordersList, ...bookingItemsList, ...extensionsList];
      combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return combined;
    } catch (e) {
      debugPrint('⚠️ [REQUESTS_DATA_SOURCE] getClientRequests Error: $e');
      return [];
    }
  }

  @override
  Future<void> markRequestAsAttended(String id, {bool isCanteenOrder = false}) async {
    debugPrint('🔵 [REQUESTS_DATA_SOURCE] Marking request as attended: id=$id, isCanteenOrder=$isCanteenOrder');
    try {
      if (id.startsWith('item_')) {
        final itemId = id.replaceFirst('item_', '');
        await client
            .from('booking_items')
            .update({
              'is_attended': true,
              'is_read': true,
            })
            .eq('id', itemId);
      } else if (id.startsWith('ext_')) {
        final bookingId = id.replaceFirst('ext_', '');
        await client
            .from('bookings')
            .update({
              'extension_status': 'approved',
            })
            .eq('id', bookingId);
      } else if (isCanteenOrder) {
        await client
            .from('canteen_orders')
            .update({
              'status': 'completed',
              'is_attended': true,
            })
            .eq('id', id);
      } else {
        try {
          await client
              .from('notifications')
              .update({
                'is_read': true,
                'is_attended': true,
              })
              .eq('id', id);
        } catch (_) {
          await client
              .from('client_requests')
              .update({
                'is_read': true,
                'is_attended': true,
              })
              .eq('id', id);
        }
      }
      debugPrint('🟢 [REQUESTS_DATA_SOURCE] Successfully marked request $id as attended');
    } catch (e) {
      debugPrint('🔴 [REQUESTS_DATA_SOURCE] Failed to mark request $id as attended: $e');
      rethrow;
    }
  }
}
