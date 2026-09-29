import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/audit/data/datasources/audit_remote_datasource.dart';
import 'package:play_spot_dashboard/features/audit/data/models/audit_log_model.dart';
import 'package:play_spot_dashboard/features/audit/data/repositories/audit_repository_impl.dart';
import 'package:play_spot_dashboard/features/audit/domain/entities/audit_log_entity.dart';
import 'package:play_spot_dashboard/features/audit/domain/usecases/get_audit_logs_usecase.dart';

class MockAuditRemoteDataSource extends Mock implements AuditRemoteDataSource {}

void main() {
  late AuditRepositoryImpl repository;
  late MockAuditRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockAuditRemoteDataSource();
    repository = AuditRepositoryImpl(mockRemoteDataSource);
  });

  const tParams = GetAuditLogsParams(loungeId: 'lounge-123');
  final tModel = AuditLogModel(
    id: 'evt-1',
    entityType: 'booking',
    action: 'created',
    createdAt: DateTime(2026, 3, 30),
  );

  test('getAuditLogs should return AuditLogPaginatedResult when datasource succeeds', () async {
    when(() => mockRemoteDataSource.getAuditLogs(tParams))
        .thenAnswer((_) async => [tModel]);

    final result = await repository.getAuditLogs(tParams);

    expect(result.isRight(), true);
    result.fold(
      (failure) => fail('Should have succeeded'),
      (paginated) {
        expect(paginated.logs.length, 1);
        expect(paginated.logs.first.id, 'evt-1');
      },
    );
    verify(() => mockRemoteDataSource.getAuditLogs(tParams)).called(1);
  });

  test('getAuditLogs should return ServerFailure when datasource throws exception', () async {
    when(() => mockRemoteDataSource.getAuditLogs(tParams))
        .thenThrow(Exception('RPC Exception'));

    final result = await repository.getAuditLogs(tParams);

    expect(result.isLeft(), true);
    result.fold(
      (failure) => expect(failure, isA<ServerFailure>()),
      (_) => fail('Should have failed'),
    );
  });
}
