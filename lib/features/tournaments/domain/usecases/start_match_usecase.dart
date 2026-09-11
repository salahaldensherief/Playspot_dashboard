import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../repositories/tournament_repository.dart';

class StartMatchParams extends Equatable {
  final String matchId;
  final String? roomId;

  const StartMatchParams({
    required this.matchId,
    this.roomId,
  });

  @override
  List<Object?> get props => [matchId, roomId];
}

class StartMatchUseCase implements UseCase<void, StartMatchParams> {
  final TournamentRepository repository;

  StartMatchUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(StartMatchParams params) {
    return repository.startMatch(params.matchId, roomId: params.roomId);
  }
}
