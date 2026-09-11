import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/tournament_entity.dart';
import '../repositories/tournament_repository.dart';

class GetTournamentsParams extends Equatable {
  final String? loungeId;
  final String? status;

  const GetTournamentsParams({this.loungeId, this.status});

  @override
  List<Object?> get props => [loungeId, status];
}

class GetTournamentsUseCase implements UseCase<List<TournamentEntity>, GetTournamentsParams> {
  final TournamentRepository repository;

  GetTournamentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TournamentEntity>>> call(GetTournamentsParams params) {
    return repository.getTournaments(
      loungeId: params.loungeId,
      status: params.status,
    );
  }
}
