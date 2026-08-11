import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_cubit.dart';
import 'package:play_spot_dashboard/features/auth/presentation/login/login_state.dart';
import 'package:play_spot_dashboard/features/lounges/presentation/cubit/lounge_cubit.dart';
import 'package:play_spot_dashboard/features/auth/domain/entities/user_entity.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

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
    if (authState.user?.role == UserRole.loungeAdmin && authState.user?.loungeId != null && !_locationCaptured) {
      _captureLocation(authState.user!.loungeId!);
    }
  }

  Future<void> _captureLocation(String loungeId) async {
    try {
      // Using browser geolocation API directly for Web as requested
      if (html.window.navigator.geolocation != null) {
        html.window.navigator.geolocation.getCurrentPosition().then((pos) {
          final lat = pos.coords?.latitude?.toDouble();
          final lng = pos.coords?.longitude?.toDouble();
          
          if (lat != null && lng != null) {
            context.read<LoungeCubit>().updateLoungeLocation(loungeId, lat, lng);
            setState(() => _locationCaptured = true);
            debugPrint('Successfully captured and updated lounge location: $lat, $lng');
          }
        }).catchError((e) {
          debugPrint('Error capturing location: $e');
        });
      }
    } catch (e) {
      debugPrint('Geolocation not supported or failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state.user?.role == UserRole.loungeAdmin && state.user?.loungeId != null && !_locationCaptured) {
          _captureLocation(state.user!.loungeId!);
        }
      },
      child: widget.child,
    );
  }
}
