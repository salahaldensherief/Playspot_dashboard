import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/constants/app_constants.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/services/location_service.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/lounges/domain/repositories/lounge_repository.dart';

class GeolocationHandler extends StatefulWidget {
  final Widget child;
  const GeolocationHandler({super.key, required this.child});

  @override
  State<GeolocationHandler> createState() => _GeolocationHandlerState();
}

class _GeolocationHandlerState extends State<GeolocationHandler> {
  @override
  void initState() {
    super.initState();
    _checkAndCapture();
  }

  void _checkAndCapture() {
    final authState = context.read<LoginCubit>().state;
    if (authState.user?.isStaff == true && authState.userLounge != null && !authState.locationCaptured) {
      _captureLocation();
    }
  }

  Future<void> _captureLocation() async {
    final loginCubit = context.read<LoginCubit>();
    final authState = loginCubit.state;
    final lounge = authState.userLounge;
    
    if (lounge == null || authState.locationCaptured) return;

    try {
      final locationService = sl<LocationService>();
      final position = await locationService.getCurrentPosition();
      
      if (position != null && mounted) {
        final cityName = await locationService.getCityFromPosition(position, context);
        
        await sl<LoungeRepository>().updateLounge(
          lounge.copyWith(
            lat: position.latitude,
            lng: position.longitude,
            city: cityName ?? lounge.city,
          ),
        );
        
        // Mark as captured in global state to prevent loops
        loginCubit.markLocationCaptured();
        debugPrint('${AppConstants.locationCaptureSuccess}${position.latitude}, ${position.longitude}, $cityName');
      }
    } catch (e) {
      debugPrint('${AppConstants.locationCaptureError}$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, LoginState>(
      listenWhen: (prev, curr) => prev.locationCaptured != curr.locationCaptured || prev.userLounge != curr.userLounge,
      listener: (context, state) {
        if (state.user?.isStaff == true && state.userLounge != null && !state.locationCaptured) {
          _captureLocation();
        }
      },
      child: widget.child,
    );
  }
}
