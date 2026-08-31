import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import '../repositories/booking_repository.dart';

class ConfirmCashPayment {
  final BookingRepository repository;

  ConfirmCashPayment(this.repository);

  Future<Either<Failure, void>> call(
    String bookingId, {
    String? shiftId,
    double? discountAmount,
    double? discountPercentage,
    String? discountReason,
  }) async {
    return await repository.confirmCashPayment(
      bookingId,
      shiftId: shiftId,
      discountAmount: discountAmount,
      discountPercentage: discountPercentage,
      discountReason: discountReason,
    );
  }
}
