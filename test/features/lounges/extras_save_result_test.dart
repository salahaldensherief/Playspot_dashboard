import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/features/lounges/domain/entities/extra_entity.dart';
import 'package:play_spot_dashboard/features/lounges/domain/repositories/lounge_repository.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/extras_cubit.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/extras_state.dart';

class MockLoungeRepository extends Mock implements LoungeRepository {}
void main() {
  const extra = ExtraEntity(id: 'extra', loungeId: 'lounge', nameAr: 'مشروب',
    nameEn: 'Drink', price: 20, category: 'drinks', costPrice: 10);
  test('failed create reports false so dialog keeps entered data', () async {
    final repository = MockLoungeRepository();
    when(() => repository.addExtra(extra)).thenAnswer((_) async => const Left(ServerFailure('permission denied')));
    final cubit = ExtrasCubit(repository);
    expect(await cubit.addExtra(extra), isFalse);
    expect(cubit.state.status, ExtrasStatus.failure);
    expect(cubit.state.errorMessage, 'permission denied');
    await cubit.close();
  });
  test('failed update reports false rather than closing as successful', () async {
    final repository = MockLoungeRepository();
    when(() => repository.updateExtra(extra)).thenAnswer((_) async => const Left(ServerFailure('connection failed')));
    final cubit = ExtrasCubit(repository);
    expect(await cubit.updateExtra(extra), isFalse);
    expect(cubit.state.status, ExtrasStatus.failure);
    await cubit.close();
  });
  test('successful update waits for persistence and refresh', () async {
    final repository = MockLoungeRepository();
    when(() => repository.updateExtra(extra)).thenAnswer((_) async => const Right(null));
    when(() => repository.getExtras('lounge', forceRefresh: false))
        .thenAnswer((_) async => const Right([extra]));
    final cubit = ExtrasCubit(repository);
    expect(await cubit.updateExtra(extra), isTrue);
    expect(cubit.state.extras, [extra]);
    expect(cubit.state.status, ExtrasStatus.success);
    await cubit.close();
  });
}
