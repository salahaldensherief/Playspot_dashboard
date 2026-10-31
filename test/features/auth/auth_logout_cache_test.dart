import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/auth/data/repositories/auth_repository_impl.dart';
import '../../support/mock_dashboard_auth_remote.dart';
import '../../support/mock_local_cache_service.dart';

void main() {
  for (final remoteFails in [false, true]) {
    for (final cacheFails in [false, true]) {
      test(
        'logout handles remote failure $remoteFails and cleanup failure $cacheFails',
        () async {
          final remote = MockDashboardAuthRemote();
          final cache = MockLocalCacheService();
          when(remote.logout).thenAnswer((_) async {
            if (remoteFails) throw StateError('auth.test_failure');
          });
          when(cache.clearAll).thenAnswer((_) async {
            if (cacheFails) throw StateError('cache.remove_failed');
          });
          final result = await AuthRepositoryImpl(remote, cache).logout();
          expect(result.isLeft(), remoteFails || cacheFails);
          if (cacheFails) {
            expect(
              result.fold((failure) => failure, (_) => null),
              const CacheFailure('cache.remove_failed'),
            );
          }
          verifyInOrder([remote.logout, cache.clearAll]);
          verifyNoMoreInteractions(remote);
          verifyNoMoreInteractions(cache);
        },
      );
    }
  }
}
