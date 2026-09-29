import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/audit/domain/entities/audit_log_entity.dart';
import 'package:play_spot_dashboard/features/audit/domain/repositories/audit_repository.dart';
import 'package:play_spot_dashboard/features/audit/domain/usecases/get_audit_logs_usecase.dart';

class MockAuditRepository extends Mock implements AuditRepository {}

void main() {
  late GetAuditLogsUsecase usecase;
  late MockAuditRepository mockRepository;

  setUp(() {
    mockRepository = MockAuditRepository();
    usecase = GetAuditLogsUsecase(mockRepository);
  });

  const tParams = GetAuditLogsParams(loungeId: 'lounge-123');
  final tAuditLog = AuditLogEntity(
    id: 'evt-1',
    entityType: 'booking',
    action: 'created',
    createdAt: DateTime(2026, 3, 30),
  );
  final tResult = AuditLogPaginatedResult(
    logs: [tAuditLog],
    hasMore: false,
  );

  test('should return AuditLogPaginatedResult from repository when success', () async {
    when(() => mockRepository.getAuditLogs(tParams))
        .thenAnswer((_) async => Right(tResult));

    final result = await usecase(tParams);

    expect(result, Right(tResult));
    verify(() => mockRepository.getAuditLogs(tParams)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return ServerFailure when repository fails', () async {
    const tFailure = ServerFailure('Database query error');
    when(() => mockRepository.getAuditLogs(tParams))
        .thenAnswer((_) async => const Left(tFailure));

    final result = await usecase(tParams);

    expect(result, const Left(tFailure));
    verify(() => mockRepository.getAuditLogs(tParams)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
