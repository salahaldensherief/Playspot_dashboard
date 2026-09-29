import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/pricing_quote_entity.dart';
import '../repositories/pricing_repository.dart';

class QuoteBookingPriceParams extends Equatable {
  final String roomId;
  final String date;
  final String startTime;
  final String endTime;
  final String playMode;
  final int extraControllers;
  final String? couponCode;

  const QuoteBookingPriceParams({
    required this.roomId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.playMode = 'single',
    this.extraControllers = 0,
    this.couponCode,
  });

  @override
  List<Object?> get props => [
        roomId,
        date,
        startTime,
        endTime,
        playMode,
        extraControllers,
        couponCode,
      ];
}

class QuoteBookingPriceUseCase
    implements UseCase<PricingQuoteEntity, QuoteBookingPriceParams> {
  final PricingRepository repository;

  QuoteBookingPriceUseCase(this.repository);

  @override
  Future<Either<Failure, PricingQuoteEntity>> call(
    QuoteBookingPriceParams params,
  ) {
    return repository.quoteBookingPrice(
      roomId: params.roomId,
      date: params.date,
      startTime: params.startTime,
      endTime: params.endTime,
      playMode: params.playMode,
      extraControllers: params.extraControllers,
      couponCode: params.couponCode,
    );
  }
}
