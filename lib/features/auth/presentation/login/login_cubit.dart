import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/utils/app_logger.dart';
import 'package:play_spot_dashboard/core/services/location_service.dart';
import '../../domain/usecases/login_params.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../lounges/domain/entities/lounge.dart';
import '../../../lounges/domain/repositories/lounge_repository.dart';
import '../../../../core/usecases/base_usecase.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final LoungeRepository loungeRepository;
  final LocationService locationService;
  final AuthRepository authRepository;

  double? _lastUpdatedLat;
  double? _lastUpdatedLng;

  LoginCubit({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.loungeRepository,
    required this.locationService,
    required this.authRepository,
  }) : super(const LoginState());

  Future<void> checkInitialAuth({BuildContext? context}) async {
    AppLogger.info('LoginCubit: checking initial auth');
    emit(state.copyWith(status: LoginStatus.checking));
    final result = await getCurrentUserUseCase(NoParams());
    result.fold(
      (failure) {
        AppLogger.error('LoginCubit: initial auth check failed: ${failure.message}');
        emit(state.copyWith(status: LoginStatus.unauthenticated));
      },
      (user) async {
        AppLogger.info('LoginCubit: user role: ${user?.role}');
        if (user != null) {
          emit(state.copyWith(
            status: LoginStatus.authenticated,
            user: user,
            isSetupCompleted: user.isSetupCompleted,
          ));
          
          updateUserLocation();

          if (user.isStaff && user.loungeId != null) {
            _handleLoungeAdminAuth(user, context: context);
          }
        } else {
          emit(state.copyWith(status: LoginStatus.unauthenticated));
        }
      },
    );
  }

  Future<void> login(String email, String password, { BuildContext? context}) async {
    AppLogger.info('LoginCubit: logging in');
    emit(state.copyWith(status: LoginStatus.loading));
    final result = await loginUseCase(LoginParams(email: email, password: password));
    result.fold(
      (failure) {
        AppLogger.error('LoginCubit: login failed: ${failure.message}');
        emit(state.copyWith(status: LoginStatus.failure, errorMessage: failure.message));
      },
      (user) async {
        AppLogger.info('LoginCubit: login success');
        emit(state.copyWith(
          status: LoginStatus.authenticated,
          user: user,
          isSetupCompleted: user.isSetupCompleted,
        ));

        updateUserLocation();

        if (user.isStaff && user.loungeId != null) {
          _handleLoungeAdminAuth(user, context: context);
        }
      },
    );
  }

  Future<void> _handleLoungeAdminAuth(UserEntity user, {BuildContext? context}) async {
    final loungeId = user.loungeId;
    if (loungeId == null) return;

    final loungeResult = await loungeRepository.getLoungeById(loungeId);
    loungeResult.fold(
      (_) => null,
      (lounge) async {
        emit(state.copyWith(userLounge: lounge));
        // We removed the location capture from here to avoid redundancy and potential loops.
        // It's now handled by the GeolocationHandler in the UI Shell.
      },
    );
  }

  /// Reloads profile to refresh isSetupCompleted status
  Future<void> refreshProfile() async {
    final result = await getCurrentUserUseCase(NoParams());
    result.fold(
      (_) => null,
      (user) {
        if (user != null) {
          emit(state.copyWith(
            user: user,
            isSetupCompleted: user.isSetupCompleted,
          ));
        }
      },
    );
  }

  void updateUser(UserEntity user) {
    emit(state.copyWith(user: user, isSetupCompleted: user.isSetupCompleted));
  }

  Future<void> updateUserLocation() async {
    emit(state.copyWith(isLoadingLocation: true, locationErrorMessage: null));
    try {
      final hasPermission = await locationService.checkPermissions();
      if (!hasPermission) {
        emit(state.copyWith(
          isLoadingLocation: false,
          locationErrorMessage: 'يرجى تفعيل صلاحية الوصول إلى الموقع من إعدادات الجهاز',
        ));
        return;
      }

      final position = await locationService.getCurrentPosition();
      if (position == null) {
        emit(state.copyWith(
          isLoadingLocation: false,
          locationErrorMessage: 'الموقع غير واضح أو تعذر تحديد الإحداثيات',
        ));
        return;
      }

      // Check if user location hasn't changed significantly (less than 500 meters)
      if (_lastUpdatedLat != null && _lastUpdatedLng != null) {
        final distanceInMeters = Geolocator.distanceBetween(
          _lastUpdatedLat!,
          _lastUpdatedLng!,
          position.latitude,
          position.longitude,
        );
        if (distanceInMeters < 500) {
          AppLogger.info('LoginCubit: User location hasn\'t changed significantly (${distanceInMeters.toStringAsFixed(1)}m < 500m). Skipping DB update.');
          emit(state.copyWith(isLoadingLocation: false));
          return;
        }
      }

      final result = await authRepository.updateUserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      result.fold(
        (failure) {
          String errorMessage = 'حدث خطأ مؤقت، يرجى المحاولة مرة أخرى';
          final errStr = failure.message;
          if (errStr.contains('422') || errStr.contains('غير مضافة')) {
            errorMessage = 'عذراً، المدينة غير مضافة حالياً للنظام';
          } else if (errStr.contains('401') || errStr.contains('انتهت صلاحية الجلسة')) {
            errorMessage = 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى';
            logout();
          } else if (errStr.isNotEmpty) {
            errorMessage = errStr;
          }
          emit(state.copyWith(
            isLoadingLocation: false,
            locationErrorMessage: errorMessage,
          ));
        },
        (updatedUser) {
          _lastUpdatedLat = position.latitude;
          _lastUpdatedLng = position.longitude;
          emit(state.copyWith(
            isLoadingLocation: false,
            user: updatedUser,
            locationErrorMessage: null,
          ));
        },
      );
    } catch (e) {
      String errorMessage = 'حدث خطأ مؤقت، يرجى المحاولة مرة أخرى';
      final errStr = e.toString();
      if (errStr.contains('422')) {
        errorMessage = 'عذراً، المدينة غير مضافة حالياً للنظام';
      } else if (errStr.contains('401')) {
        errorMessage = 'انتهت صلاحية الجلسة، يرجى تسجيل الدخول مرة أخرى';
        logout();
      }
      emit(state.copyWith(
        isLoadingLocation: false,
        locationErrorMessage: errorMessage,
      ));
    }
  }

  void markLocationCaptured() {
    emit(state.copyWith(locationCaptured: true));
  }

  void updateUserLounge(Lounge lounge) {
    emit(state.copyWith(userLounge: lounge));
  }

  Future<void> refreshUserLounge(String loungeId, {bool forceRefresh = false}) async {
    final loungeResult = await loungeRepository.getLoungeById(loungeId, forceRefresh: forceRefresh);
    loungeResult.fold(
      (_) => null,
      (lounge) => emit(state.copyWith(userLounge: lounge)),
    );
  }

  Future<void> logout() async {
    _lastUpdatedLat = null;
    _lastUpdatedLng = null;
    await logoutUseCase(NoParams());
    emit(const LoginState(status: LoginStatus.unauthenticated));
  }
}
