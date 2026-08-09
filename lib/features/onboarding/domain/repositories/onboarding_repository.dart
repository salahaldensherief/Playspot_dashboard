import 'package:dartz/dartz.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/lounge.dart';

abstract class OnboardingRepository {
  Future<Either<Failure, Lounge>> setupLounge(Lounge lounge);
}
