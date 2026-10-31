import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/audit/domain/entities/audit_log_entity.dart';
import 'package:play_spot_dashboard/features/audit/domain/usecases/export_audit_logs_csv_usecase.dart';
import 'package:play_spot_dashboard/features/audit/domain/usecases/get_audit_logs_usecase.dart';
import 'package:play_spot_dashboard/features/audit/presentation/audit_cubit.dart';
import 'package:play_spot_dashboard/features/audit/presentation/audit_state.dart';

class MockGetAuditLogsUsecase extends Mock implements GetAuditLogsUsecase {}

class MockExportAuditLogsCsvUsecase extends Mock
    implements ExportAuditLogsCsvUsecase {}

void main() {
  setUpAll(() {
    registerFallbackValue(GetAuditLogsParams(loungeId: 'fallback'));
    registerFallbackValue(ExportAuditLogsParams(loungeId: 'fallback'));
  });
  late AuditCubit cubit;
  late MockGetAuditLogsUsecase mockGetAuditLogsUsecase;
  late MockExportAuditLogsCsvUsecase mockExportAuditLogsCsvUsecase;

  setUp(() {
    mockGetAuditLogsUsecase = MockGetAuditLogsUsecase();
    mockExportAuditLogsCsvUsecase = MockExportAuditLogsCsvUsecase();

    cubit = AuditCubit(
      getAuditLogsUsecase: mockGetAuditLogsUsecase,
      exportAuditLogsCsvUsecase: mockExportAuditLogsCsvUsecase,
    );
  });

  tearDown(() {
    cubit.close();
  });

  final tLog = AuditLogEntity(
    id: 'evt-100',
    entityType: 'shift',
    action: 'opened',
    createdAt: DateTime(2026, 3, 30),
  );
  final tResult = AuditLogPaginatedResult(logs: [tLog], hasMore: false);

  test(
    'late response from previous lounge cannot replace current logs',
    () async {
      final old = Completer<Either<Failure, AuditLogPaginatedResult>>();
      when(() => mockGetAuditLogsUsecase(any())).thenAnswer((call) async {
        final params = call.positionalArguments.first as GetAuditLogsParams;
        return params.loungeId == 'old' ? old.future : Right(tResult);
      });
      final pending = cubit.loadAuditLogs(loungeId: 'old');
      await cubit.loadAuditLogs(loungeId: 'new');
      old.complete(const Left(ServerFailure('stale failure')));
      await pending;
      expect(cubit.state.logs, [tLog]);
      expect(cubit.state.status, AuditStatus.success);
      expect(cubit.state.errorMessage, isNull);
    },
  );

  test('refresh invalidates pending pagination and clears loading', () async {
    final page = Completer<Either<Failure, AuditLogPaginatedResult>>();
    when(() => mockGetAuditLogsUsecase(any())).thenAnswer((call) async {
      final params = call.positionalArguments.first as GetAuditLogsParams;
      if (params.lastId != null) return page.future;
      return Right(AuditLogPaginatedResult(logs: [tLog], hasMore: true));
    });
    await cubit.loadAuditLogs(loungeId: 'lounge');
    final pending = cubit.loadMoreLogs(loungeId: 'lounge');
    expect(cubit.state.isLoadingMore, isTrue);
    await cubit.loadAuditLogs(loungeId: 'lounge');
    page.complete(Right(tResult));
    await pending;
    expect(cubit.state.logs, [tLog]);
    expect(cubit.state.isLoadingMore, isFalse);
  });

  test('completion after disposal does not emit', () async {
    final response = Completer<Either<Failure, AuditLogPaginatedResult>>();
    when(
      () => mockGetAuditLogsUsecase(any()),
    ).thenAnswer((_) => response.future);
    final pending = cubit.loadAuditLogs(loungeId: 'lounge');
    await cubit.close();
    response.complete(Right(tResult));
    await expectLater(pending, completes);
    expect(() => cubit.resetFilters(loungeId: 'lounge'), returnsNormally);
  });

  test('retry clears the previous error while loading', () async {
    when(
      () => mockGetAuditLogsUsecase(any()),
    ).thenAnswer((_) async => const Left(ServerFailure('failed')));
    await cubit.loadAuditLogs(loungeId: 'lounge');
    final response = Completer<Either<Failure, AuditLogPaginatedResult>>();
    when(
      () => mockGetAuditLogsUsecase(any()),
    ).thenAnswer((_) => response.future);
    final pending = cubit.loadAuditLogs(loungeId: 'lounge');
    expect(cubit.state.errorMessage, isNull);
    response.complete(Right(tResult));
    await pending;
    expect(cubit.state.errorMessage, isNull);
  });

  test('stale successful export cannot download after lounge change', () async {
    when(
      () => mockGetAuditLogsUsecase(any()),
    ).thenAnswer((_) async => Right(tResult));
    final export = Completer<Either<Failure, String>>();
    when(
      () => mockExportAuditLogsCsvUsecase(any()),
    ).thenAnswer((_) => export.future);
    await cubit.loadAuditLogs(loungeId: 'old');
    final pending = cubit.exportCsv(loungeId: 'old');
    await cubit.loadAuditLogs(loungeId: 'new');
    export.complete(const Right('old lounge data'));
    await pending;
    expect(cubit.state.isExporting, isFalse);
    expect(cubit.state.exportSuccess, isFalse);
  });

  test('initial state should be AuditState()', () {
    expect(cubit.state, const AuditState());
  });

  test(
    'loadAuditLogs emits [loading, success] when usecase succeeds',
    () async {
      const loungeId = 'lounge-1';
      final params = GetAuditLogsParams(loungeId: loungeId, limit: 20);

      when(
        () => mockGetAuditLogsUsecase(params),
      ).thenAnswer((_) async => Right(tResult));

      final expectedStates = [
        const AuditState(status: AuditStatus.loading, logs: []),
        AuditState(status: AuditStatus.success, logs: [tLog], hasMore: false),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadAuditLogs(loungeId: loungeId);
    },
  );

  test('loadAuditLogs emits [loading, failure] when usecase fails', () async {
    const loungeId = 'lounge-1';
    final params = GetAuditLogsParams(loungeId: loungeId, limit: 20);

    when(
      () => mockGetAuditLogsUsecase(params),
    ).thenAnswer((_) async => const Left(ServerFailure('Error loading logs')));

    final expectedStates = [
      const AuditState(status: AuditStatus.loading, logs: []),
      const AuditState(
        status: AuditStatus.failure,
        errorMessage: 'Error loading logs',
      ),
    ];

    expectLater(cubit.stream, emitsInOrder(expectedStates));

    await cubit.loadAuditLogs(loungeId: loungeId);
  });
}
