import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class HardwareBridgeService {
  static const String primaryBridgeUrl = 'http://127.0.0.1:8443';
  static const String secondaryBridgeUrl = 'http://local.playspot.me:8443';
  static const Duration defaultTimeout = Duration(seconds: 2);

  /// Pings local Bridge Agent before starting/stopping a room session.
  /// If [isManualRoom] is true, bypasses hardware bridge pinging automatically.
  Future<bool> pingBridge({
    required String roomId,
    required String action, // 'turn-on' or 'turn-off'
    bool isManualRoom = false,
  }) async {
    if (isManualRoom) {
      debugPrint('ℹ️ [HARDWARE_BRIDGE] Room $roomId is manual mode; bypassing bridge agent.');
      return true;
    }

    final sanitizedAction = Uri.encodeComponent(action.trim().toLowerCase());
    final endpoints = [
      '$primaryBridgeUrl/$sanitizedAction',
      '$secondaryBridgeUrl/$sanitizedAction',
    ];

    for (final endpoint in endpoints) {
      try {
        debugPrint('🔵 [HARDWARE_BRIDGE] Pinging $endpoint for room $roomId...');
        final uri = Uri.parse(endpoint).replace(queryParameters: {
          'roomId': roomId.trim(),
        });
        final response = await http.get(uri).timeout(defaultTimeout);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          debugPrint('🟢 [HARDWARE_BRIDGE] Agent responded successfully at $endpoint');
          return true;
        }
      } catch (e) {
        debugPrint('⚠️ [HARDWARE_BRIDGE] Bridge ping failed at $endpoint: $e');
      }
    }

    debugPrint('🔴 [HARDWARE_BRIDGE] Local agent not responding on port 8443.');
    return false;
  }
}
