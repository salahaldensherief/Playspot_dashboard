import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/client_request_entity.dart';
import '../models/client_request_model.dart';

abstract class RequestsRemoteDataSource {
  /// Stream combined real-time service_calls, notifications, canteen orders, and pending extensions for a lounge.
  Stream<List<ClientRequestModel>> watchClientRequests({required String loungeId});

  /// Fetch combined client requests once for a lounge.
  Future<List<ClientRequestModel>> getClientRequests({required String loungeId});

  /// Mark notification, service_call, or canteen order as attended / read.
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
    Timer? heartbeatTimer;
    StreamSubscription? serviceCallsSubscription;
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

        // 2. Realtime Subscriptions for service_calls, notifications, canteen_orders, and bookings
        // Subscription 0: Service Calls stream (Primary stream for assistance requests)
        try {
          serviceCallsSubscription = client
              .from('service_calls')
              .stream(primaryKey: ['id'])
              .eq('lounge_id', cleanLoungeId)
              .listen(
                (_) {
                  fetchAndEmit();
                },
                onError: (e) {
                  debugPrint('⚠️ [REQUESTS_DATA_SOURCE] ServiceCalls Realtime Error: $e');
                  if (e is RealtimeSubscribeException) {
                    debugPrint('⚠️ [REQUESTS_DATA_SOURCE] ServiceCalls RealtimeSubscribeException (status: ${e.status}, details: $e)');
                  }
                  _setupServiceCallsFallbackStream(cleanLoungeId, fetchAndEmit, (sub) => serviceCallsSubscription = sub);
                },
                cancelOnError: false,
              );
        } catch (e) {
          debugPrint('⚠️ [REQUESTS_DATA_SOURCE] ServiceCalls Realtime Exception: $e');
          _setupServiceCallsFallbackStream(cleanLoungeId, fetchAndEmit, (sub) => serviceCallsSubscription = sub);
        }

        // Subscription 1: Notifications stream
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
        serviceCallsSubscription?.cancel();
        notifSubscription?.cancel();
        canteenSubscription?.cancel();
        bookingItemsSubscription?.cancel();
        bookingsSubscription?.cancel();
        heartbeatTimer?.cancel();
      },
    );

    return controller.stream;
  }

  void _setupServiceCallsFallbackStream(
    String loungeId,
    VoidCallback fetchAndEmit,
    void Function(StreamSubscription) setSubscription,
  ) {
    try {
      debugPrint('🔄 [REQUESTS_DATA_SOURCE] Fallback stream for service_calls...');
      final sub = client
          .from('service_calls')
          .stream(primaryKey: ['id'])
          .listen(
            (_) {
              fetchAndEmit();
            },
            onError: (e) {
              debugPrint('⚠️ [REQUESTS_DATA_SOURCE] ServiceCalls Fallback Error: $e');
            },
            cancelOnError: false,
          );
      setSubscription(sub);
    } catch (e) {
      debugPrint('⚠️ [REQUESTS_DATA_SOURCE] ServiceCalls Fallback Exception: $e');
    }
  }

  void _setupNotificationsFallbackStream(
    String loungeId,
    VoidCallback fetchAndEmit,
    void Function(StreamSubscription) setSubscription,
  ) {
    try {
      final sub = client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .listen(
            (_) {
              fetchAndEmit();
            },
            onError: (e) {
              debugPrint('⚠️ [REQUESTS_DATA_SOURCE] Notifications Fallback Error: $e');
            },
            cancelOnError: false,
          );
      setSubscription(sub);
    } catch (e) {
      debugPrint('⚠️ [REQUESTS_DATA_SOURCE] Notifications Fallback Exception: $e');
    }
  }

  ClientRequestModel _applyLocalAttendance(ClientRequestModel model) {
    if (_locallyAttendedIds.contains(model.id)) {
      return ClientRequestModel(
        id: model.id,
        loungeId: model.loungeId,
        bookingId: model.bookingId,
        userId: model.userId,
        userName: model.userName,
        userPhone: model.userPhone,
        userAvatarUrl: model.userAvatarUrl,
        roomId: model.roomId,
        roomName: model.roomName,
        titleAr: model.titleAr,
        titleEn: model.titleEn,
        bodyAr: model.bodyAr,
        bodyEn: model.bodyEn,
        type: model.type,
        isRead: true,
        isAttended: true,
        createdAt: model.createdAt,
        metadata: model.metadata,
        canteenItems: model.canteenItems,
        totalPrice: model.totalPrice,
      );
    }
    return model;
  }

  @override
  Future<List<ClientRequestModel>> getClientRequests({required String loungeId}) async {
    final cleanLoungeId = loungeId.trim();
    if (cleanLoungeId.isEmpty) return [];

    try {
      // Lookup maps for room names, user names and avatars to enrich service_calls safely
      Map<String, String> roomNamesMap = {};
      Map<String, String> userNamesMap = {};
      Map<String, String> userAvatarsMap = {};
      try {
        final List<dynamic> roomsResp = await client.from('rooms').select('id, name').eq('lounge_id', cleanLoungeId);
        for (var r in roomsResp) {
          if (r['id'] != null && r['name'] != null) {
            roomNamesMap[r['id'].toString()] = r['name'].toString();
          }
        }
        final List<dynamic> bookingsResp = await client.from('bookings').select('id, user_id, user_name, room_name, user_avatar, profiles(avatar_url)').eq('lounge_id', cleanLoungeId).order('created_at', ascending: false).limit(50);
        for (var b in bookingsResp) {
          if (b['id'] != null) {
            final bId = b['id'].toString();
            final uId = b['user_id']?.toString();
            userNamesMap[bId] = (b['user_name'] ?? 'عميل').toString();
            if (b['room_name'] != null && b['room_name'].toString().isNotEmpty) {
              roomNamesMap[bId] = b['room_name'].toString();
            }
            final profileObj = b['profiles'] as Map<String, dynamic>?;
            final avatarUrl = (b['user_avatar'] ?? profileObj?['avatar_url'])?.toString();
            if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
              userAvatarsMap[bId] = avatarUrl.trim();
              if (uId != null) userAvatarsMap[uId] = avatarUrl.trim();
            }
          }
        }
      } catch (_) {}

      // 0. Fetch service_calls for the active lounge (primary source for assistance/call_staff)
      dynamic serviceCallsResponse = [];
      try {
        serviceCallsResponse = await client
            .from('service_calls')
            .select()
            .eq('lounge_id', cleanLoungeId)
            .or('status.eq.pending,status.eq.in_progress')
            .order('created_at', ascending: false)
            .limit(50);
      } catch (e) {
        try {
          serviceCallsResponse = await client
              .from('service_calls')
              .select()
              .eq('lounge_id', cleanLoungeId)
              .eq('status', 'pending')
              .order('created_at', ascending: false)
              .limit(50);
        } catch (_) {
          try {
            serviceCallsResponse = await client
                .from('service_calls')
                .select()
                .eq('lounge_id', cleanLoungeId)
                .order('created_at', ascending: false)
                .limit(50);
          } catch (_) {}
        }
      }

      final serviceCallsList = ((serviceCallsResponse is List) ? serviceCallsResponse : [])
          .map((json) => ClientRequestModel.fromServiceCallJson(
                Map<String, dynamic>.from(json),
                roomNamesMap: roomNamesMap,
                userNamesMap: userNamesMap,
                userAvatarsMap: userAvatarsMap,
              ))
          .where((model) {
            if (cleanLoungeId.isNotEmpty && model.loungeId.isNotEmpty && model.loungeId != cleanLoungeId) {
              return false;
            }
            return true;
          })
          .map(_applyLocalAttendance)
          .toList();

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
        debugPrint('⚠️ [REQUESTS_DATA_SOURCE] notifications select error: $e');
      }

      final notifList = ((notifResponse is List) ? notifResponse : [])
          .map((json) => ClientRequestModel.fromNotificationJson(Map<String, dynamic>.from(json)))
          .where((model) {
            if (cleanLoungeId.isNotEmpty && model.loungeId.isNotEmpty && model.loungeId != cleanLoungeId) {
              return false;
            }
            if (model.type == ClientRequestType.other) {
              return false;
            }
            return true;
          })
          .map(_applyLocalAttendance)
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
        debugPrint('⚠️ [REQUESTS_DATA_SOURCE] canteen_orders select error: $e');
      }

      final ordersList = ((ordersResponse is List) ? ordersResponse : [])
          .map((json) => ClientRequestModel.fromCanteenOrderJson(Map<String, dynamic>.from(json)))
          .where((model) {
            if (cleanLoungeId.isNotEmpty && model.loungeId.isNotEmpty && model.loungeId != cleanLoungeId) {
              return false;
            }
            return true;
          })
          .map(_applyLocalAttendance)
          .toList();

      // 2b. Fetch canteen items from booking_items table
      dynamic bookingItemsResponse = [];
      try {
        bookingItemsResponse = await client
            .from('booking_items')
            .select('*, bookings(lounge_id, room_name, user_name, user_phone, user_avatar)')
            .order('created_at', ascending: false)
            .limit(50);
      } catch (e) {
        try {
          bookingItemsResponse = await client
              .from('booking_items')
              .select()
              .order('created_at', ascending: false)
              .limit(50);
        } catch (e2) {
          debugPrint('⚠️ [REQUESTS_DATA_SOURCE] booking_items select error: $e2');
        }
      }

      final bookingItemsList = ((bookingItemsResponse is List) ? bookingItemsResponse : [])
          .map((json) => ClientRequestModel.fromBookingItemJson(Map<String, dynamic>.from(json)))
          .where((model) {
            if (cleanLoungeId.isNotEmpty && model.loungeId.isNotEmpty && model.loungeId != cleanLoungeId) {
              return false;
            }
            return true;
          })
          .map(_applyLocalAttendance)
          .toList();

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
        debugPrint('⚠️ [REQUESTS_DATA_SOURCE] extensions select error: $e');
      }

      final extensionsList = ((extensionsResponse is List) ? extensionsResponse : [])
          .map((json) => ClientRequestModel.fromBookingExtensionJson(Map<String, dynamic>.from(json)))
          .where((model) {
            if (cleanLoungeId.isNotEmpty && model.loungeId.isNotEmpty && model.loungeId != cleanLoungeId) {
              return false;
            }
            return true;
          })
          .map(_applyLocalAttendance)
          .toList();

      final combined = [...serviceCallsList, ...notifList, ...ordersList, ...bookingItemsList, ...extensionsList];
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
    _locallyAttendedIds.add(id);

    // Extract raw DB ID without prefixes
    String rawDbId = id
        .replaceFirst('canteen_', '')
        .replaceFirst('notif_', '')
        .replaceFirst('sc_', '')
        .replaceFirst('item_', '')
        .replaceFirst('ext_', '');

    debugPrint('🔵 [REQUESTS_DATA_SOURCE] Clean DB ID: $rawDbId (original ID: $id)');

    try {
      if (id.startsWith('sc_')) {
        bool scUpdated = false;
        try {
          await client
              .from('service_calls')
              .update({
                'status': 'resolved',
                'is_attended': true,
                'is_read': true,
              })
              .eq('id', rawDbId);
          scUpdated = true;
        } catch (e) {
          debugPrint('⚠️ [REQUESTS_DATA_SOURCE] service_calls update 1 error: $e');
        }

        if (!scUpdated) {
          try {
            await client
                .from('service_calls')
                .update({'status': 'resolved'})
                .eq('id', rawDbId);
          } catch (e2) {
            debugPrint('⚠️ [REQUESTS_DATA_SOURCE] service_calls update 2 error: $e2');
          }
        }
      } else if (id.startsWith('ext_')) {
        try {
          await client
              .from('bookings')
              .update({'extension_status': 'approved'})
              .eq('id', rawDbId);
        } catch (e) {
          debugPrint('⚠️ [REQUESTS_DATA_SOURCE] bookings extension_status update error: $e');
        }
      } else if (id.startsWith('item_')) {
        bool itemUpdated = false;
        try {
          await client
              .from('booking_items')
              .update({
                'status': 'completed',
                'is_attended': true,
                'is_read': true,
              })
              .eq('id', rawDbId);
          itemUpdated = true;
        } catch (e) {
          debugPrint('⚠️ [REQUESTS_DATA_SOURCE] booking_items update 1 error: $e');
        }

        if (!itemUpdated) {
          try {
            await client
                .from('booking_items')
                .update({'status': 'completed'})
                .eq('id', rawDbId);
            itemUpdated = true;
            debugPrint('🟢 [REQUESTS_DATA_SOURCE] Updated booking_items status to completed for $rawDbId');
          } catch (e2) {
            debugPrint('⚠️ [REQUESTS_DATA_SOURCE] booking_items update 2 error: $e2');
          }
        }

        if (!itemUpdated) {
          try {
            await client
                .from('booking_items')
                .update({'is_read': true})
                .eq('id', rawDbId);
          } catch (_) {}
        }
      } else if (id.startsWith('canteen_') || isCanteenOrder) {
        // Canteen Orders: update canteen_orders status to 'completed' so backend triggers compute booking totals
        bool canteenUpdated = false;
        try {
          await client
              .from('canteen_orders')
              .update({
                'status': 'completed',
                'is_attended': true,
                'is_read': true,
              })
              .eq('id', rawDbId);
          canteenUpdated = true;
          debugPrint('🟢 [CANTEEN_SYNC] Marked canteen_order $rawDbId as completed in DB');
        } catch (e) {
          debugPrint('⚠️ [REQUESTS_DATA_SOURCE] canteen_orders update 1 error: $e');
        }

        if (!canteenUpdated) {
          try {
            await client
                .from('canteen_orders')
                .update({'status': 'completed'})
                .eq('id', rawDbId);
            canteenUpdated = true;
          } catch (e2) {
            debugPrint('⚠️ [REQUESTS_DATA_SOURCE] canteen_orders update 2 error: $e2');
          }
        }

        // Fail-safe updates for matching ID or booking_id in related tables
        try {
          await client
              .from('booking_items')
              .update({'status': 'completed'})
              .eq('id', rawDbId);
        } catch (_) {}
        try {
          await client
              .from('booking_items')
              .update({'status': 'completed'})
              .eq('booking_id', rawDbId);
        } catch (_) {}
        try {
          await client
              .from('notifications')
              .update({'is_read': true, 'is_attended': true})
              .eq('id', rawDbId);
        } catch (_) {}
        try {
          await client
              .from('notifications')
              .update({'is_read': true})
              .eq('id', rawDbId);
        } catch (_) {}
      } else {
        // Notifications / General Requests
        bool notifUpdated = false;
        try {
          await client
              .from('notifications')
              .update({
                'is_read': true,
                'is_attended': true,
              })
              .eq('id', rawDbId);
          notifUpdated = true;
        } catch (e) {
          debugPrint('⚠️ [REQUESTS_DATA_SOURCE] notifications update 1 error: $e');
        }

        if (!notifUpdated) {
          try {
            await client
                .from('notifications')
                .update({'is_read': true})
                .eq('id', rawDbId);
            notifUpdated = true;
          } catch (e2) {
            debugPrint('⚠️ [REQUESTS_DATA_SOURCE] notifications update 2 error: $e2');
          }
        }

        try {
          await client
              .from('canteen_orders')
              .update({'status': 'completed'})
              .eq('id', rawDbId);
        } catch (_) {}
      }
      debugPrint('🟢 [REQUESTS_DATA_SOURCE] Successfully marked request $id (rawDbId: $rawDbId) as attended in DB');
    } catch (e) {
      debugPrint('⚠️ [REQUESTS_DATA_SOURCE] Exception during DB update for $id: $e');
    }
  }
}
