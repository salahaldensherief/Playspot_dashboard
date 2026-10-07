import 'package:flutter/foundation.dart';
import 'package:play_spot_dashboard/features/bookings/data/models/booking_model.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingMutationHelper {
  final SupabaseClient client;
  final Future<void> Function(String voucherCode, String bookingId)
  consumeVoucher;
  final Future<Map<String, dynamic>> Function(String voucherCode)
  validateVoucher;

  BookingMutationHelper({
    required this.client,
    required this.consumeVoucher,
    required this.validateVoucher,
  });

  Future<void> executeCreateBooking(BookingModel booking) async {
    final voucherCode = booking.voucherCode?.trim();
    if (voucherCode != null && voucherCode.isNotEmpty) {
      throw StateError(
        'Vouchers require a linked customer account and are not supported for walk-in bookings.',
      );
    }

    final extraItems = booking.extras.map((extra) {
      final extraId = (extra['id'] ?? extra['extra_id'])?.toString().trim();
      if (extraId == null || extraId.isEmpty) {
        throw ArgumentError('Invalid booking extra: missing extra_id');
      }

      final rawQuantity = extra['quantity'] ?? extra['qty'] ?? 1;
      final quantity = rawQuantity is num
          ? rawQuantity.toInt()
          : int.tryParse(rawQuantity.toString()) ?? 1;

      return {
        'extra_id': extraId,
        'quantity': quantity,
      };
    }).toList();

    final response = await client.rpc(
      'create_manual_booking_admin',
      params: {
        'p_lounge_id': booking.loungeId,
        'p_room_id': booking.roomId,
        'p_booking_date': booking.date.toIso8601String().split('T')[0],
        'p_start_time': booking.startTime,
        'p_duration_minutes': booking.durationMinutes,
        'p_customer_name': booking.userName,
        'p_customer_phone': booking.userPhone,
        'p_play_mode':
            (booking.playMode == null || booking.playMode!.trim().isEmpty)
            ? 'single'
            : booking.playMode!.trim(),
        'p_extra_items': extraItems,
        'p_start_immediately': booking.status == BookingStatus.inProgress,
      },
    );

    if (response is! Map || response['success'] != true) {
      throw const PostgrestException(
        message: 'Manual booking command did not complete successfully',
        code: 'P0001',
      );
    }

    debugPrint(
      '🟢 [BookingMutationHelper] Server-authoritative manual booking created: '
      '${response['booking_id']}',
    );
  }}
