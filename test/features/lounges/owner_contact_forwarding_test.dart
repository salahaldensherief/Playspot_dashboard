import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:play_spot_dashboard/features/lounges/domain/repositories/lounge_repository.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_cubit.dart';

class _Repository extends Mock implements LoungeRepository {}

void main() {
  test(
    'owner creation forwards separate contacts and refreshes the list',
    () async {
      final repository = _Repository();
      when(
        () => repository.createLoungeWithOwner(
          email: 'owner@example.invalid',
          password: 'fixture-password',
          ownerName: 'Owner',
          loungeName: 'Venue',
          city: 'Cairo',
          address: 'Venue address',
          phone: '01234567890',
          ownerPhone: '01987654321',
        ),
      ).thenAnswer((_) async => const Right('venue'));
      when(
        () => repository.getLounges(forceRefresh: true),
      ).thenAnswer((_) async => const Right([]));
      final cubit = LoungeCubit(repository);
      addTearDown(cubit.close);
      expect(
        await cubit.createLoungeWithOwner(
          ownerEmail: 'owner@example.invalid',
          ownerPassword: 'fixture-password',
          ownerName: 'Owner',
          loungeName: 'Venue',
          city: 'Cairo',
          address: 'Venue address',
          phone: '01234567890',
          ownerPhone: '01987654321',
        ),
        isTrue,
      );
      verify(
        () => repository.createLoungeWithOwner(
          email: 'owner@example.invalid',
          password: 'fixture-password',
          ownerName: 'Owner',
          loungeName: 'Venue',
          city: 'Cairo',
          address: 'Venue address',
          phone: '01234567890',
          ownerPhone: '01987654321',
        ),
      ).called(1);
      verify(() => repository.getLounges(forceRefresh: true)).called(1);
    },
  );
}
