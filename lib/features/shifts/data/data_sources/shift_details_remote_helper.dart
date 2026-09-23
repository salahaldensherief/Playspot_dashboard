import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shift_audit_log_model.dart';
import '../models/shift_expense_model.dart';
import '../models/shift_payment_model.dart';

class ShiftDetailsRemoteHelper {
  final SupabaseClient _supabase;

  ShiftDetailsRemoteHelper(this._supabase);

  Future<void> addShiftExpense(ShiftExpenseModel expense) async {
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
    debugPrint('🔵 [ShiftDetailsRemoteHelper] Inserting shift expense: $payload');
    await _supabase.from('shift_expenses').insert(payload);
    debugPrint('🟢 [ShiftDetailsRemoteHelper] Inserted shift expense successfully');
  }

  Future<List<ShiftExpenseModel>> fetchShiftExpenses(String shiftId) async {
    debugPrint('🔵 [ShiftDetailsRemoteHelper] Fetching shift expenses for shiftId: $shiftId');
    final response = await _supabase
        .from('shift_expenses')
        .select('*, profiles:created_by(full_name)')
        .eq('shift_id', shiftId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ShiftExpenseModel.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  Future<List<ShiftPaymentModel>> fetchShiftPayments(String shiftId) async {
    try {
      debugPrint('🔵 [ShiftDetailsRemoteHelper] Fetching shift payments for shiftId: $shiftId');
      final response = await _supabase
          .from('shift_payments')
          .select('*')
          .eq('shift_id', shiftId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ShiftPaymentModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e) {
      debugPrint('⚠️ [ShiftDetailsRemoteHelper] fetchShiftPayments table query failed ($e), falling back to bookings');
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
        debugPrint('⚠️ [ShiftDetailsRemoteHelper] Fallback fetchShiftPayments failed: $fallbackErr');
        return [];
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchShiftBookings(String shiftId) async {
    try {
      debugPrint('🔵 [ShiftDetailsRemoteHelper] Fetching shift bookings for shiftId: $shiftId');
      final response = await _supabase
          .from('bookings')
          .select('*, profiles:user_id(full_name, phone_number), rooms:room_id(name)')
          .eq('shift_id', shiftId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Map<String, dynamic>.from(json as Map))
          .toList();
    } catch (e) {
      debugPrint('⚠️ [ShiftDetailsRemoteHelper] fetchShiftBookings error: $e');
      return [];
    }
  }

  Future<List<ShiftAuditLogModel>> fetchShiftAuditLogs(String shiftId) async {
    try {
      debugPrint('🔵 [ShiftDetailsRemoteHelper] Fetching shift audit logs for shiftId: $shiftId');
      final response = await _supabase
          .from('shift_audit_logs')
          .select('*, profiles:actor_user_id(full_name)')
          .eq('shift_id', shiftId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ShiftAuditLogModel.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e) {
      debugPrint('⚠️ [ShiftDetailsRemoteHelper] fetchShiftAuditLogs error: $e');
      return [];
    }
  }
}
