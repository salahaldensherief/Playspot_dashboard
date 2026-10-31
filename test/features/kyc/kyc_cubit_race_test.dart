import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/kyc/domain/entities/kyc_request.dart';
import 'package:play_spot_dashboard/features/kyc/domain/repositories/kyc_repository.dart';
import 'package:play_spot_dashboard/features/kyc/domain/usecases/kyc_usecases.dart';
import 'package:play_spot_dashboard/features/kyc/presentation/cubit/kyc_cubit.dart';
import 'package:play_spot_dashboard/features/kyc/presentation/cubit/kyc_state.dart';

class _Repository extends Mock implements KycRepository {}

void main() {
  late _Repository repository;
  late KycCubit cubit;
  const request = KycRequest(
    submissionId: 'review-1',
    revision: 1,
    loungeId: 'lounge-1',
    userId: 'owner-1',
    ownerName: 'Owner',
    ownerEmail: 'owner@example.invalid',
    loungeName: 'Lounge',
    idDocumentUrl: '',
  );
  setUp(() {
    repository = _Repository();
    cubit = KycCubit(
      submitKycUseCase: SubmitKycUseCase(repository),
      getPendingKycReviewsUseCase: GetPendingKycReviewsUseCase(repository),
      reviewKycUseCase: ReviewKycUseCase(repository),
    );
  });
  tearDown(() => cubit.close());
  void decision(Future<Either<Failure, void>> Function() response) {
    when(
      () => repository.reviewKyc(
        requestId: 'review-1',
        revision: 1,
        approve: true,
      ),
    ).thenAnswer((_) => response());
  }

  Future<bool> approve() =>
      cubit.reviewKyc(requestId: 'review-1', revision: 1, approve: true);

  test('late list result cannot overwrite a newer list', () async {
    final older = Completer<Either<Failure, List<KycRequest>>>();
    var calls = 0;
    when(() => repository.getPendingReviews()).thenAnswer(
      (_) => ++calls == 1 ? older.future : Future.value(const Right([])),
    );
    final pending = cubit.loadPendingReviews();
    await cubit.loadPendingReviews();
    older.complete(const Right([request]));
    await pending;
    expect(cubit.state.status, KycStatus.success);
    expect(cubit.state.requests, isEmpty);
  });
  test('late pre-decision list cannot restore an approved request', () async {
    final older = Completer<Either<Failure, List<KycRequest>>>();
    var calls = 0;
    when(() => repository.getPendingReviews()).thenAnswer(
      (_) => ++calls == 1 ? older.future : Future.value(const Right([])),
    );
    decision(() => Future.value(const Right(null)));
    final pending = cubit.loadPendingReviews();
    expect(await approve(), isTrue);
    older.complete(const Right([request]));
    await pending;
    expect(cubit.state.requests, isEmpty);
    expect(cubit.state.status, KycStatus.success);
  });
  test(
    'double decision sends exactly one mutation and releases loading',
    () async {
      final mutation = Completer<Either<Failure, void>>();
      decision(() => mutation.future);
      when(
        () => repository.getPendingReviews(),
      ).thenAnswer((_) async => const Right([]));
      final pending = approve();
      expect(cubit.state.status, KycStatus.loading);
      expect(await approve(), isFalse);
      mutation.complete(const Right(null));
      expect(await pending, isTrue);
      verify(
        () => repository.reviewKyc(
          requestId: 'review-1',
          revision: 1,
          approve: true,
        ),
      ).called(1);
      expect(cubit.state.status, KycStatus.success);
    },
  );
  test(
    'failed decision remains failed and does not refresh or report acceptance',
    () async {
      decision(
        () => Future.value(const Left(ServerFailure('review conflict'))),
      );
      expect(await approve(), isFalse);
      expect(cubit.state.status, KycStatus.failure);
      verifyNever(() => repository.getPendingReviews());
    },
  );
  test(
    'accepted decision remains accepted if later list refresh fails',
    () async {
      decision(() => Future.value(const Right(null)));
      when(
        () => repository.getPendingReviews(),
      ).thenAnswer((_) async => const Left(ServerFailure('offline')));
      expect(await approve(), isTrue);
      expect(cubit.state.status, KycStatus.failure);
    },
  );
  test('closing cubit while decision is pending emits no late state', () async {
    final mutation = Completer<Either<Failure, void>>();
    decision(() => mutation.future);
    final pending = approve();
    await cubit.close();
    mutation.complete(const Right(null));
    expect(await pending, isFalse);
    verifyNever(() => repository.getPendingReviews());
  });
}
