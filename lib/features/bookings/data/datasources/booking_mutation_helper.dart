import 'package:flutter/foundation.dart';
import 'package:play_spot_dashboard/features/bookings/data/models/booking_model.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingMutationHelper {
  final SupabaseClient client;
  final Future<void> Function(String voucherCode, String bookingId) consumeVoucher;
  final Future<Map<String, dynamic>> Function(String voucherCode) validateVoucher;

  BookingMutationHelper({
    required this.client,
    required this.consumeVoucher,
    required this.validateVoucher,
  });

  Future<void> executeCreateBooking(BookingModel booking) async {
    final activeShift = await client
        .from('shifts')
        .select('id')
        .eq('lounge_id', booking.loungeId)
        .or('status.eq.open,status.eq.active')
        .limit(1)
        .maybeSingle();

    if (activeShift == null) {
      throw Exception('لا توجد وردية مفتوحة حالياً لهذا المقر. يرجى فتح وردية أولاً قبل إضافة أي حجز.');
    }

    final cleanVoucherCode = booking.voucherCode?.trim().toUpperCase();
    if (cleanVoucherCode != null && cleanVoucherCode.isNotEmpty) {
      await validateVoucher(cleanVoucherCode);
    }

    final activeShiftId = activeShift['id']?.toString();
    final bookingToInsert = (activeShiftId != null && (booking.shiftId == null || booking.shiftId!.isEmpty))
        ? BookingModel(
            id: booking.id,
            userId: booking.userId,
            userName: booking.userName,
            userEmail: booking.userEmail,
            userPhone: booking.userPhone,
            loungeId: booking.loungeId,
            roomId: booking.roomId,
            loungeName: booking.loungeName,
            loungeLocation: booking.loungeLocation,
            roomName: booking.roomName,
            controllersCount: booking.controllersCount,
            screenSize: booking.screenSize,
            date: booking.date,
            startTime: booking.startTime,
            endTime: booking.endTime,
            durationMinutes: booking.durationMinutes,
            status: booking.status,
            paymentStatus: booking.paymentStatus,
            totalPrice: booking.totalPrice,
            voucherDiscount: booking.voucherDiscount,
            voucherCode: cleanVoucherCode,
            discountAmount: booking.discountAmount,
            discountPercentage: booking.discountPercentage,
            discountReason: booking.discountReason,
            extras: booking.extras,
            lat: booking.lat,
            lng: booking.lng,
            shiftId: activeShiftId,
            playMode: booking.playMode,
            roomPrice: booking.roomPrice,
          )
        : booking;

    final jsonMap = bookingToInsert.toJson();
    if (bookingToInsert.id.trim().isEmpty) {
      jsonMap.remove('id');
    }
    if (bookingToInsert.userId.trim().isEmpty) {
      jsonMap.remove('user_id');
    }
    if (bookingToInsert.shiftId == null || bookingToInsert.shiftId!.trim().isEmpty) {
      jsonMap.remove('shift_id');
    }

    final response = await client.from('bookings').insert(jsonMap).select().single();
    final createdBookingId = (response['id'] ?? bookingToInsert.id)?.toString();

    if (bookingToInsert.status == BookingStatus.inProgress &&
        createdBookingId != null &&
        createdBookingId.isNotEmpty) {
      try {
        await client.rpc('complete_booking_payment', params: {
          'p_booking_id': createdBookingId,
          'p_payment_method': 'cash',
          'p_final_amount': null,
        });
        debugPrint('🟢 [BookingMutationHelper] complete_booking_payment RPC succeeded for walk-in booking: $createdBookingId');
      } catch (e1) {
        debugPrint('⚠️ [BookingMutationHelper] complete_booking_payment RPC failed ($e1), trying start_booking_session');
        try {
          await client.rpc('start_booking_session', params: {
            'p_booking_id': createdBookingId,
          });
        } catch (e2) {
          debugPrint('⚠️ [BookingMutationHelper] start_booking_session RPC failed: $e2');
          try {
            await client
                .from('rooms')
                .update({'status': 'occupied', 'is_available': false})
                .eq('id', bookingToInsert.roomId);
          } catch (_) {}
        }
      }
    }

    if (bookingToInsert.extras.isNotEmpty && createdBookingId != null && createdBookingId.isNotEmpty) {
      final itemsToInsert = bookingToInsert.extras.map((extra) => {
            'booking_id': createdBookingId,
            'extra_id': extra['id'] ?? extra['extra_id'],
            'name': extra['name_ar'] ?? extra['name'] ?? extra['name_en'] ?? 'صنف',
            'quantity': extra['quantity'] ?? extra['qty'] ?? 1,
            'unit_price': extra['unit_price'] ?? extra['price'] ?? 0.0,
            'total_price': extra['total_price'] ??
                ((extra['unit_price'] ?? extra['price'] ?? 0.0) *
                    (extra['quantity'] ?? extra['qty'] ?? 1)),
          }).toList();

      try {
        await client.from('booking_items').insert(itemsToInsert);
      } catch (e) {
        debugPrint('⚠️ [BookingMutationHelper] Failed inserting booking_items: $e');
      }
    }

    if (cleanVoucherCode != null &&
        cleanVoucherCode.isNotEmpty &&
        createdBookingId != null &&
        createdBookingId.isNotEmpty) {
      await consumeVoucher(cleanVoucherCode, createdBookingId);
    }
  }
}
