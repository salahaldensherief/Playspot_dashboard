
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';

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
      return null;
    }
  }

  @override
  Future<String?> getCityFromPosition(Position position, BuildContext context) async {
    try {
      final locale = Localizations.localeOf(context);
      
      // Try to set the locale globally for the geocoding service
      if (locale.languageCode.isNotEmpty) {
        try {
          await setLocaleIdentifier(locale.languageCode);
        } catch (e) {
          debugPrint('Geocoding setLocaleIdentifier failed: $e');
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
      return null;
    }
  }
}
