import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shift_model.dart';
import '../models/live_shift_overview_model.dart';
import '../models/shift_expense_model.dart';
import '../models/shift_payment_model.dart';
import '../models/cashier_performance_model.dart';
import '../models/lounge_comparison_model.dart';
import '../models/shift_audit_log_model.dart';

abstract class ShiftRemoteDataSource {
  Future<List<ShiftModel>> getShifts({String? loungeId});
  Future<List<ShiftModel>> getShiftReport({
    String? loungeId,
    DateTime? startDate,
    DateTime? endDate,
    String? cashierId,
  });
  Future<List<CashierPerformanceModel>> getCashierPerformance({
    String? loungeId,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<List<LoungeComparisonModel>> getLoungeComparison({
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<ShiftModel?> getActiveShift(String loungeId);
  Future<LiveShiftOverviewModel> getLoungeLiveShiftOverview(String loungeId);
  Future<void> openShift(String loungeId, double startingCash, {String? notes});
  Future<ShiftModel> closeShift(String shiftId, double actualCash, String? notes, {String? loungeId});
  Future<void> approveShift(String shiftId, String managerId, String? notes);
  Future<void> addShiftExpense(ShiftExpenseModel expense);
  Future<List<ShiftExpenseModel>> fetchShiftExpenses(String shiftId);
  Future<List<ShiftPaymentModel>> fetchShiftPayments(String shiftId);
  Future<List<Map<String, dynamic>>> fetchShiftBookings(String shiftId);
  Future<List<ShiftAuditLogModel>> fetchShiftAuditLogs(String shiftId);
}

class ShiftRemoteDataSourceImpl implements ShiftRemoteDataSource {
  final SupabaseClient _supabase;

  ShiftRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<ShiftModel>> getShifts({String? loungeId}) async {
    var query = _supabase.from('shifts').select('*, profiles:cashier_id(full_name)');
    
    if (loungeId != null && loungeId.isNotEmpty) {
      query = query.eq('lounge_id', loungeId);
    }

    final response = await query.order('start_time', ascending: false);
    return (response as List).map((json) => ShiftModel.fromJson(json)).toList();
  }

  @override
  Future<List<ShiftModel>> getShiftReport({
    String? loungeId,
    DateTime? startDate,
    DateTime? endDate,
    String? cashierId,
  }) async {
    try {
      debugPrint('🔵 [ShiftRemoteDataSource] Calling RPC get_shift_report');
      final response = await _supabase.rpc('get_shift_report', params: {
        if (loungeId != null && loungeId.isNotEmpty) 'p_lounge_id': loungeId,
        if (startDate != null) 'p_start_date': startDate.toIso8601String(),
        if (endDate != null) 'p_end_date': endDate.toIso8601String(),
        if (cashierId != null && cashierId.isNotEmpty) 'p_cashier_id': cashierId,
      });

      if (response != null && response is List) {
        return response.map((json) => ShiftModel.fromJson(Map<String, dynamic>.from(json as Map))).toList();
      }
      return [];
    } catch (e) {
      debugPrint('⚠️ [ShiftRemoteDataSource] RPC get_shift_report error ($e), falling back to getShifts');
      return await getShifts(loungeId: loungeId);
    }
  }

  @override
  Future<List<CashierPerformanceModel>> getCashierPerformance({
    String? loungeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('🔵 [ShiftRemoteDataSource] Calling RPC get_cashier_performance');
      final response = await _supabase.rpc('get_cashier_performance', params: {
        if (loungeId != null && loungeId.isNotEmpty) 'p_lounge_id': loungeId,
        if (startDate != null) 'p_start_date': startDate.toIso8601String(),
        if (endDate != null) 'p_end_date': endDate.toIso8601String(),
      });

      if (response != null && response is List) {
        return response.map((json) => CashierPerformanceModel.fromJson(Map<String, dynamic>.from(json as Map))).toList();
      }
      return [];
    } catch (e) {
      debugPrint('⚠️ [ShiftRemoteDataSource] RPC get_cashier_performance error: $e');
      return [];
    }
  }

  @override
  Future<List<LoungeComparisonModel>> getLoungeComparison({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('🔵 [ShiftRemoteDataSource] Calling RPC get_lounge_comparison');
      final response = await _supabase.rpc('get_lounge_comparison', params: {
        if (startDate != null) 'p_start_date': startDate.toIso8601String(),
        if (endDate != null) 'p_end_date': endDate.toIso8601String(),
      });

      if (response != null && response is List) {
        return response.map((json) => LoungeComparisonModel.fromJson(Map<String, dynamic>.from(json as Map))).toList();
      }
      return [];
    } catch (e) {
      debugPrint('⚠️ [ShiftRemoteDataSource] RPC get_lounge_comparison error: $e');
      return [];
    }
  }

  @override
  Future<ShiftModel?> getActiveShift(String loungeId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('🔴 [ShiftRemoteDataSource] getActiveShift: No authenticated user found.');
        return null;
      }

      debugPrint('🔵 [ShiftRemoteDataSource] Fetching active shift for user: $userId (loungeId: $loungeId)');

      var query = _supabase
          .from('shifts')
          .select('*, profiles:cashier_id(full_name)')
          .eq('status', 'open')
          .filter('closed_at', 'is', null);

      if (loungeId.isNotEmpty) {
        query = query.eq('lounge_id', loungeId);
      } else {
        query = query.eq('cashier_id', userId);
      }

      final response = await query
          .order('start_time', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      var model = ShiftModel.fromJson(response);

      if ((model.cashierName == null || model.cashierName == 'N/A' || model.cashierName!.trim().isEmpty) && model.cashierId.isNotEmpty) {
        try {
          final profileRes = await _supabase
              .from('profiles')
              .select('full_name')
              .eq('id', model.cashierId)
              .maybeSingle();

          if (profileRes != null && profileRes['full_name'] != null) {
            final name = profileRes['full_name'].toString().trim();
            if (name.isNotEmpty) {
              model = ShiftModel(
                id: model.id,
                loungeId: model.loungeId,
                cashierId: model.cashierId,
                cashierName: name,
                startingCash: model.startingCash,
                cashRevenue: model.cashRevenue,
                digitalRevenue: model.digitalRevenue,
                expensesTotal: model.expensesTotal,
                cashDropsTotal: model.cashDropsTotal,
                expectedCash: model.expectedCash,
                actualCash: model.actualCash,
                discrepancy: model.discrepancy,
                status: model.status,
                startTime: model.startTime,
                endTime: model.endTime,
                notes: model.notes,
                isApproved: model.isApproved,
                approvedBy: model.approvedBy,
                approvedAt: model.approvedAt,
                managerNotes: model.managerNotes,
              );
            }
          }
        } catch (profileErr) {
          debugPrint('⚠️ [ShiftRemoteDataSource] Cashier name profile lookup failed: $profileErr');
        }
      }

      return model;
    } catch (e, stack) {
      debugPrint('🔴 [ShiftRemoteDataSource] Exception in getActiveShift: $e');
      debugPrint('🔴 [ShiftRemoteDataSource] StackTrace: $stack');
      rethrow;
    }
  }

  @override
  Future<LiveShiftOverviewModel> getLoungeLiveShiftOverview(String loungeId) async {
    try {
      final response = await _supabase.rpc('get_lounge_live_shift_overview', params: {
        'p_lounge_id': loungeId,
      });
      if (response != null) {
        final jsonMap = Map<String, dynamic>.from(response is List && response.isNotEmpty ? response.first as Map : response as Map);
        var overview = LiveShiftOverviewModel.fromJson(jsonMap);

        if (overview.hasActiveShift && (overview.cashierName == null || overview.cashierName == 'N/A' || overview.cashierName!.trim().isEmpty)) {
          try {
            final activeShift = await getActiveShift(loungeId);
            if (activeShift != null && activeShift.cashierName != 'N/A') {
              overview = LiveShiftOverviewModel(
                hasActiveShift: overview.hasActiveShift,
                shiftId: overview.shiftId ?? activeShift.id,
                cashierName: activeShift.cashierName,
                cashierAvatar: overview.cashierAvatar,
                cashierPhone: overview.cashierPhone,
                startTime: overview.startTime ?? activeShift.startTime,
                startingCash: overview.startingCash ?? activeShift.startingCash,
                cashInDrawer: overview.cashInDrawer,
                digitalPayments: overview.digitalPayments,
                activeSessions: overview.activeSessions,
                closedBookings: overview.closedBookings,
              );
            }
          } catch (e) {
            debugPrint('⚠️ [ShiftRemoteDataSource] Cashier name overview resolution error: $e');
          }
        }

        return overview;
      }
    } catch (e) {
      debugPrint('⚠️ [ShiftRemoteDataSource] RPC get_lounge_live_shift_overview error ($e)');
    }

    return LiveShiftOverviewModel(
      hasActiveShift: false,
      shiftId: null,
      cashierName: null,
      cashierAvatar: null,
      cashierPhone: null,
      startTime: null,
      startingCash: 0.0,
      cashInDrawer: 0.0,
      digitalPayments: 0.0,
      activeSessions: 0,
      closedBookings: 0,
    );
  }

  @override
  Future<void> openShift(String loungeId, double startingCash, {String? notes}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      debugPrint('🔵 [ShiftRemoteDataSource] Opening shift - User: $userId, Lounge: $loungeId, Float: $startingCash');

      // Check if there is already an open shift for this lounge
      final existingOpenShift = await _supabase
          .from('shifts')
          .select('id')
          .eq('lounge_id', loungeId)
          .eq('status', 'open')
          .maybeSingle();

      if (existingOpenShift != null) {
        throw Exception('يوجد شفت مفتوح بالفعل لهذا الفرع.');
      }

      try {
        await _supabase.rpc('open_lounge_shift', params: {
          'p_lounge_id': loungeId,
          'p_starting_cash': startingCash,
          'p_notes': notes,
        });
        debugPrint('🟢 [ShiftRemoteDataSource] RPC open_lounge_shift successful');
      } catch (rpcErr) {
        if (rpcErr.toString().contains('already') || rpcErr.toString().contains('مفتوح')) {
          throw Exception('يوجد شفت مفتوح بالفعل لهذا الفرع.');
        }
        debugPrint('⚠️ [ShiftRemoteDataSource] RPC open_lounge_shift failed ($rpcErr), trying legacy open_shift');
        try {
          await _supabase.rpc('open_shift', params: {
            'p_lounge_id': loungeId,
            'p_starting_cash': startingCash,
          });
          debugPrint('🟢 [ShiftRemoteDataSource] Legacy RPC open_shift successful');
        } catch (legacyErr) {
          debugPrint('⚠️ [ShiftRemoteDataSource] RPC open_shift failed ($legacyErr), falling back to direct insert');
          await _supabase.from('shifts').insert({
            'cashier_id': userId,
            'lounge_id': loungeId,
            'starting_cash': startingCash,
            'status': 'open',
            'start_time': DateTime.now().toIso8601String(),
          });
        }
      }

      debugPrint('🟢 [ShiftRemoteDataSource] Shift opened successfully');
    } catch (e, stack) {
      debugPrint('🔴 [ShiftRemoteDataSource] Exception in openShift: $e');
      debugPrint('🔴 [ShiftRemoteDataSource] StackTrace: $stack');
      rethrow;
    }
  }

  @override
  Future<ShiftModel> closeShift(String shiftId, double actualCash, String? notes, {String? loungeId}) async {
    try {
      debugPrint('🔵 [ShiftRemoteDataSource] Attempting to close shift: $shiftId (loungeId: $loungeId) with cash: $actualCash');

      if (loungeId != null && loungeId.isNotEmpty) {
        try {
          final response = await _supabase.rpc('close_lounge_shift', params: {
            'p_lounge_id': loungeId,
            'p_actual_cash_counted': actualCash,
            'p_notes': notes,
          });

          debugPrint('🔵 [ShiftRemoteDataSource] close_lounge_shift RPC response: $response');

          if (response != null) {
            Map<String, dynamic> shiftJson = {};
            if (response is List && response.isNotEmpty) {
              shiftJson = Map<String, dynamic>.from(response.first as Map);
            } else if (response is Map) {
              shiftJson = Map<String, dynamic>.from(response);
            }

            if (shiftJson.containsKey('current_shift') && shiftJson['current_shift'] is Map) {
              shiftJson = Map<String, dynamic>.from(shiftJson['current_shift'] as Map);
            } else if (shiftJson.containsKey('shift') && shiftJson['shift'] is Map) {
              shiftJson = Map<String, dynamic>.from(shiftJson['shift'] as Map);
            }

            if (shiftJson.isNotEmpty && shiftJson.containsKey('id')) {
              return ShiftModel.fromJson(shiftJson);
            }
          }
        } catch (rpcErr) {
          debugPrint('⚠️ [ShiftRemoteDataSource] RPC close_lounge_shift failed ($rpcErr), attempting legacy fallback...');
        }
      }

      try {
        final response = await _supabase.rpc('close_shift', params: {
          'p_shift_id': shiftId,
          'p_actual_cash': actualCash,
          'p_notes': notes,
        });

        debugPrint('🔵 [ShiftRemoteDataSource] close_shift RPC response: $response');

        if (response != null) {
          return ShiftModel.fromJson(Map<String, dynamic>.from(response as Map));
        }
      } catch (rpcErr) {
        debugPrint('⚠️ [ShiftRemoteDataSource] RPC close_shift failed ($rpcErr), attempting direct table update fallback...');
      }

      final nowIso = DateTime.now().toIso8601String();

      final List<dynamic> updatedList = await _supabase
          .from('shifts')
          .update({
            'status': 'closed',
            'actual_cash_counted': actualCash,
            'end_time': nowIso,
            'closed_at': nowIso,
            if (notes != null && notes.isNotEmpty) 'notes': notes,
          })
          .eq('id', shiftId)
          .select('*, profiles:cashier_id(full_name)');

      if (updatedList.isNotEmpty) {
        debugPrint('🟢 [ShiftRemoteDataSource] Direct table update closeShift successful!');
        return ShiftModel.fromJson(Map<String, dynamic>.from(updatedList.first as Map));
      }

      throw Exception('فشل تقفيل الشيفت: يرجى التأكد من صلاحيات قاعدة البيانات');
    } catch (e, stack) {
      debugPrint('🔴 [ShiftRemoteDataSource] Exception in closeShift: $e');
      debugPrint('🔴 [ShiftRemoteDataSource] StackTrace: $stack');
      rethrow;
    }
  }

  @override
  Future<void> approveShift(String shiftId, String managerId, String? notes) async {
    await _supabase.rpc('approve_shift', params: {
      'p_shift_id': shiftId,
      'p_manager_id': managerId,
      'p_notes': notes,
    });
  }

  @override
  Future<void> addShiftExpense(ShiftExpenseModel expense) async {
    // Check if shift is open
    final shiftRes = await _supabase
        .from('shifts')
        .select('status')
        .eq('id', expense.shiftId)
        .maybeSingle();

    if (shiftRes != null && shiftRes['status'] != 'open') {
      throw Exception('لا يمكن إضافة مصروفات أو مدفوعات على شفت مغلق.');
    }

    final userId = _supabase.auth.currentUser?.id;
    final payload = expense.toJson();
    if (userId != null) {
      payload['created_by'] = userId;
    }
    final rawId = payload['id']?.toString() ?? '';
    if (rawId.length != 36 || !rawId.contains('-')) {
      payload.remove('id');
    }
    debugPrint('🔵 [ShiftRemoteDataSource] Inserting shift expense: $payload');
    await _supabase.from('shift_expenses').insert(payload);
    debugPrint('🟢 [ShiftRemoteDataSource] Inserted shift expense successfully');
  }

  @override
  Future<List<ShiftExpenseModel>> fetchShiftExpenses(String shiftId) async {
    debugPrint('🔵 [ShiftRemoteDataSource] Fetching shift expenses for shiftId: $shiftId');
    final response = await _supabase
        .from('shift_expenses')
        .select('*, profiles:created_by(full_name)')
        .eq('shift_id', shiftId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ShiftExpenseModel.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  @override
  Future<List<ShiftPaymentModel>> fetchShiftPayments(String shiftId) async {
    try {
      debugPrint('🔵 [ShiftRemoteDataSource] Fetching shift payments for shiftId: $shiftId');
      final response = await _supabase
          .from('shift_payments')
          .select('*')
          .eq('shift_id', shiftId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ShiftPaymentModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e) {
      debugPrint('⚠️ [ShiftRemoteDataSource] fetchShiftPayments table query failed ($e), falling back to bookings query');
      try {
        final response = await _supabase
            .from('bookings')
            .select('*')
            .eq('shift_id', shiftId)
            .order('created_at', ascending: false);

        return (response as List).map((b) {
          final amount = (b['total_price'] ?? b['price'] ?? 0).toDouble();
          final method = (b['payment_method'] ?? 'cash').toString();
          return ShiftPaymentModel(
            id: (b['id'] ?? '').toString(),
            shiftId: shiftId,
            amount: amount,
            paymentMethod: method,
            category: 'play_time',
            bookingId: (b['id'] ?? '').toString(),
            createdAt: b['created_at'] != null ? DateTime.parse(b['created_at'].toString()) : DateTime.now(),
          );
        }).toList();
      } catch (fallbackErr) {
        debugPrint('⚠️ [ShiftRemoteDataSource] Fallback fetchShiftPayments failed: $fallbackErr');
        return [];
      }
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchShiftBookings(String shiftId) async {
    try {
      debugPrint('🔵 [ShiftRemoteDataSource] Fetching shift bookings for shiftId: $shiftId');
      final response = await _supabase
          .from('bookings')
          .select('*, profiles:user_id(full_name, phone_number), rooms:room_id(name)')
          .eq('shift_id', shiftId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Map<String, dynamic>.from(json as Map))
          .toList();
    } catch (e) {
      debugPrint('⚠️ [ShiftRemoteDataSource] fetchShiftBookings error: $e');
      return [];
    }
  }

  @override
  Future<List<ShiftAuditLogModel>> fetchShiftAuditLogs(String shiftId) async {
    try {
      debugPrint('🔵 [ShiftRemoteDataSource] Fetching shift audit logs for shiftId: $shiftId');
      final response = await _supabase
          .from('shift_audit_logs')
          .select('*, profiles:actor_user_id(full_name)')
          .eq('shift_id', shiftId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ShiftAuditLogModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e) {
      debugPrint('⚠️ [ShiftRemoteDataSource] fetchShiftAuditLogs error: $e');
      return [];
    }
  }
}
