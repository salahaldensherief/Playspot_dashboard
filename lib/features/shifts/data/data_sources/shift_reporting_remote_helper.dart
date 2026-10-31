import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cashier_performance_model.dart';
import '../models/lounge_comparison_model.dart';
import '../models/shift_model.dart';

class ShiftReportingRemoteHelper {
  final SupabaseClient _supabase;

  ShiftReportingRemoteHelper(this._supabase);

  Future<List<ShiftModel>> getShiftReport({
    String? loungeId,
    DateTime? startDate,
    DateTime? endDate,
    String? cashierId,
    required Future<List<ShiftModel>> Function({String? loungeId})
    fallbackFetcher,
  }) async {
    try {
      debugPrint(
        '🔵 [ShiftReportingRemoteHelper] Calling RPC get_shift_report',
      );
      final response = await _supabase.rpc(
        'get_shift_report',
        params: {
          if (loungeId != null && loungeId.isNotEmpty) 'p_lounge_id': loungeId,
          if (startDate != null) 'p_start_date': startDate.toIso8601String(),
          if (endDate != null) 'p_end_date': endDate.toIso8601String(),
          if (cashierId != null && cashierId.isNotEmpty)
            'p_cashier_id': cashierId,
        },
      );

      if (response != null && response is List) {
        return response
            .map(
              (json) =>
                  ShiftModel.fromJson(Map<String, dynamic>.from(json as Map)),
            )
            .toList();
      }
      throw const FormatException('Invalid shift report response');
    } catch (e) {
      debugPrint(
        '⚠️ [ShiftReportingRemoteHelper] RPC get_shift_report error: $e',
      );
      // An unfiltered shift list cannot stand in for an authoritative report.
      rethrow;
    }
  }

  Future<List<CashierPerformanceModel>> getCashierPerformance({
    String? loungeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint(
        '🔵 [ShiftReportingRemoteHelper] Calling RPC get_cashier_performance',
      );
      final response = await _supabase.rpc(
        'get_cashier_performance',
        params: {
          if (loungeId != null && loungeId.isNotEmpty) 'p_lounge_id': loungeId,
          if (startDate != null) 'p_start_date': startDate.toIso8601String(),
          if (endDate != null) 'p_end_date': endDate.toIso8601String(),
        },
      );

      if (response != null && response is List) {
        return response
            .map(
              (json) => CashierPerformanceModel.fromJson(
                Map<String, dynamic>.from(json as Map),
              ),
            )
            .toList();
      }
      throw const FormatException('Invalid cashier performance response');
    } catch (e) {
      debugPrint(
        '⚠️ [ShiftReportingRemoteHelper] RPC get_cashier_performance error: $e',
      );
      rethrow;
    }
  }

  Future<List<LoungeComparisonModel>> getLoungeComparison({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint(
        '🔵 [ShiftReportingRemoteHelper] Calling RPC get_lounge_comparison',
      );
      final response = await _supabase.rpc(
        'get_lounge_comparison',
        params: {
          if (startDate != null) 'p_start_date': startDate.toIso8601String(),
          if (endDate != null) 'p_end_date': endDate.toIso8601String(),
        },
      );

      if (response != null && response is List) {
        return response
            .map(
              (json) => LoungeComparisonModel.fromJson(
                Map<String, dynamic>.from(json as Map),
              ),
            )
            .toList();
      }
      throw const FormatException('Invalid lounge comparison response');
    } catch (e) {
      debugPrint(
        '⚠️ [ShiftReportingRemoteHelper] RPC get_lounge_comparison error: $e',
      );
      rethrow;
    }
  }
}
