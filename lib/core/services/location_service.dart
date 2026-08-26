import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../constants/app_constants.dart';

abstract class LocationService {
  Future<Position?> getCurrentPosition();
  Future<bool> checkPermissions();
  Future<String?> getCityFromPosition(Position position, BuildContext context);
}

class LocationServiceImpl implements LocationService {
  @override
  Future<bool> checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  @override
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('${AppConstants.currentPositionError}$e');
      return null;
    }
  }

  @override
  Future<String?> getCityFromPosition(Position position, BuildContext context) async {
    // geocoding package does not support Flutter Web.
    // kIsWeb is the standard check, using identical(0, 0.0) as extra safety for JS environment.
    if (kIsWeb || identical(0, 0.0)) return null; 

    try {
      final locale = Localizations.maybeLocaleOf(context);
      
      // Try to set the locale globally for the geocoding service
      if (locale != null && locale.languageCode.isNotEmpty) {
        try {
          await setLocaleIdentifier(locale.languageCode);
        } catch (e) {
          debugPrint('${AppConstants.geocodingFailed}$e');
        }
      }

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return placemark.locality ?? placemark.subAdministrativeArea ?? placemark.administrativeArea;
      }
      return null;
    } catch (e) {
      debugPrint('${AppConstants.cityFromPositionError}$e');
      return null;
    }
  }
}
