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

  test('initial state should be AuditState()', () {
    expect(cubit.state, const AuditState());
  });

  test('loadAuditLogs emits [loading, success] when usecase succeeds', () async {
    const loungeId = 'lounge-1';
    final params = GetAuditLogsParams(loungeId: loungeId, limit: 20);

    when(() => mockGetAuditLogsUsecase(params))
        .thenAnswer((_) async => Right(tResult));

    final expectedStates = [
      const AuditState(status: AuditStatus.loading, logs: []),
      AuditState(
        status: AuditStatus.success,
        logs: [tLog],
        hasMore: false,
      ),
    ];

    expectLater(cubit.stream, emitsInOrder(expectedStates));

    await cubit.loadAuditLogs(loungeId: loungeId);
  });

  test('loadAuditLogs emits [loading, failure] when usecase fails', () async {
    const loungeId = 'lounge-1';
    final params = GetAuditLogsParams(loungeId: loungeId, limit: 20);

    when(() => mockGetAuditLogsUsecase(params))
        .thenAnswer((_) async => const Left(ServerFailure('Error loading logs')));

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
