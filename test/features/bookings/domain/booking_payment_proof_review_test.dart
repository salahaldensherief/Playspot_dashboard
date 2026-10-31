import 'package:flutter_test/flutter_test.dart';
import 'package:play_spot_dashboard/features/bookings/domain/entities/booking.dart';

void main() {
  Booking booking({
    BookingStatus status = BookingStatus.upcoming,
    PaymentStatus paymentStatus = PaymentStatus.unpaid,
    String? receiptUrl,
  }) => Booking(
    id: 'booking-1',
    userId: 'user-1',
    loungeId: 'lounge-1',
    roomId: 'room-1',
    date: DateTime(2026, 10, 20),
    startTime: '12:00',
    endTime: '13:00',
    status: status,
    paymentStatus: paymentStatus,
    receiptUrl: receiptUrl,
    totalPrice: 100,
  );

  test('pending verification needs review even before receipt is visible', () {
    expect(
      booking(
        status: BookingStatus.pendingVerification,
      ).needsPaymentProofReview,
      isTrue,
    );
  });

  test('unpaid uploaded receipt needs review before status catches up', () {
    expect(
      booking(receiptUrl: 'payment-proofs/file').needsPaymentProofReview,
      isTrue,
    );
  });

  test('paid or blank receipts do not need review', () {
    expect(
      booking(
        paymentStatus: PaymentStatus.paid,
        receiptUrl: 'payment-proofs/file',
      ).needsPaymentProofReview,
      isFalse,
    );
    expect(booking(receiptUrl: '  ').needsPaymentProofReview, isFalse);
    expect(booking().needsPaymentProofReview, isFalse);
  });
}
