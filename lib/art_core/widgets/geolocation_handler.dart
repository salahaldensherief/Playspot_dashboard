import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/core/di/di.dart';
import 'package:play_spot_dashboard/core/services/location_service.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/lounges/domain/repositories/lounge_repository.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';

class GeolocationHandler extends StatefulWidget {
  final Widget child;
  const GeolocationHandler({super.key, required this.child});

  @override
  State<GeolocationHandler> createState() => _GeolocationHandlerState();
}

class _GeolocationHandlerState extends State<GeolocationHandler> {
  bool _locationCaptured = false;

  @override
  void initState() {
    super.initState();
    _checkAndCapture();
  }

  void _checkAndCapture() {
    final authState = context.read<LoginCubit>().state;
    if (authState.user?.isStaff == true && authState.userLounge != null && !_locationCaptured) {
      _captureLocation();
    }
  }

  Future<void> _captureLocation() async {
    final authState = context.read<LoginCubit>().state;
    final lounge = authState.userLounge;
    
    if (lounge == null) return;

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
        
        setState(() => _locationCaptured = true);
        debugPrint('Successfully captured and updated lounge location and city: ${position.latitude}, ${position.longitude}, $cityName');
      }
    } catch (e) {
      debugPrint('Error capturing location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state.user?.isStaff == true && state.userLounge != null && !_locationCaptured) {
          _captureLocation();
        }
      },
      child: widget.child,
    );
  }
}
