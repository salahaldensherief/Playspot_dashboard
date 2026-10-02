import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:geolocator/geolocator.dart';
import 'package:play_spot_dashboard/core/error/failures.dart';
import 'package:play_spot_dashboard/core/services/location_service.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
import 'package:play_spot_dashboard/features/auth/domain/repositories/auth_repository.dart';
import 'package:play_spot_dashboard/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:play_spot_dashboard/features/auth/domain/usecases/login_usecase.dart';
import 'package:play_spot_dashboard/features/auth/domain/usecases/logout_usecase.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/lounges/domain/repositories/lounge_repository.dart';

class _Auth extends Mock implements AuthRepository {}

class _Lounge extends Mock implements LoungeRepository {}

class _Location extends Mock implements LocationService {}

const oldUser = UserEntity(
  id: 'old',
  email: 'old@example.invalid',
  name: 'Old',
  role: UserRole.owner,
);
const newUser = UserEntity(
  id: 'new',
  email: 'new@example.invalid',
  name: 'New',
  role: UserRole.owner,
);
void main() {
  late _Auth auth;
  late _Location location;
  late LoginCubit cubit;
  setUp(() {
    auth = _Auth();
    location = _Location();
    when(() => location.checkPermissions()).thenAnswer((_) async => true);
    when(() => location.getCurrentPosition()).thenAnswer(
      (_) async => Position(
        longitude: 30,
        latitude: 31,
        timestamp: DateTime.utc(2026, 10, 2),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ),
    );
    when(() => auth.logout()).thenAnswer((_) async => const Right(null));
    cubit = LoginCubit(
      loginUseCase: LoginUseCase(auth),
      logoutUseCase: LogoutUseCase(auth),
      getCurrentUserUseCase: GetCurrentUserUseCase(auth),
      loungeRepository: _Lounge(),
      locationService: location,
      authRepository: auth,
    );
    cubit.updateUser(oldUser);
  });
  tearDown(() => cubit.close());
  for (final fail in [false, true]) {
    test(
      'late location ${fail ? 'failure' : 'success'} cannot alter a newer account',
      () async {
        final pending = Completer<Either<Failure, UserEntity>>();
        when(
          () => auth.updateUserLocation(latitude: 31, longitude: 30),
        ).thenAnswer((_) => pending.future);
        final loading = cubit.updateUserLocation();
        await Future<void>.delayed(Duration.zero);
        await cubit.logout();
        cubit.updateUser(newUser);
        pending.complete(
          fail
              ? const Left(ServerFailure('Authentication changed (401)'))
              : const Right(oldUser),
        );
        await loading;
        expect(cubit.state.user?.id, 'new');
        expect(cubit.state.isLoadingLocation, isFalse);
        verify(() => auth.logout()).called(1);
      },
    );
  }
  test(
    'logout clears private UI immediately while server logout is pending',
    () async {
      final pending = Completer<Either<Failure, void>>();
      when(() => auth.logout()).thenAnswer((_) => pending.future);
      final exiting = cubit.logout();
      expect(cubit.state.status, LoginStatus.unauthenticated);
      expect(cubit.state.user, isNull);
      cubit.updateUser(newUser);
      pending.complete(const Right(null));
      await exiting;
      expect(cubit.state.user?.id, 'new');
    },
  );
  test(
    'initial profile reply after logout cannot authenticate the old account',
    () async {
      final pending = Completer<Either<Failure, UserEntity?>>();
      when(() => auth.getCurrentUser()).thenAnswer((_) => pending.future);
      final checking = cubit.checkInitialAuth();
      await cubit.logout();
      pending.complete(const Right(oldUser));
      await checking;
      expect(cubit.state.status, LoginStatus.unauthenticated);
      expect(cubit.state.user, isNull);
    },
  );
  test('closing during GPS lookup prevents repository write', () async {
    final permission = Completer<bool>();
    when(
      () => location.checkPermissions(),
    ).thenAnswer((_) => permission.future);
    final loading = cubit.updateUserLocation();
    await cubit.close();
    permission.complete(true);
    await loading;
    verifyNever(() => location.getCurrentPosition());
  });
  test('a successful retry clears the old location error', () async {
    when(() => location.checkPermissions()).thenAnswer((_) async => false);
    await cubit.updateUserLocation();
    expect(cubit.state.locationErrorMessage, isNotNull);
    when(() => location.checkPermissions()).thenAnswer((_) async => true);
    when(
      () => auth.updateUserLocation(latitude: 31, longitude: 30),
    ).thenAnswer((_) async => const Right(oldUser));
    await cubit.updateUserLocation();
    expect(cubit.state.locationErrorMessage, isNull);
    expect(cubit.state.isLoadingLocation, isFalse);
  });
  test(
    'a mismatched profile response cannot leave location loading or replace the user',
    () async {
      when(
        () => auth.updateUserLocation(latitude: 31, longitude: 30),
      ).thenAnswer((_) async => const Right(newUser));
      await cubit.updateUserLocation();
      expect(cubit.state.user?.id, 'old');
      expect(cubit.state.isLoadingLocation, isFalse);
      expect(cubit.state.locationErrorMessage, isNotNull);
    },
  );
}
