import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

abstract class LocationService {
  Future<Position?> getCurrentPosition();
  Future<bool> checkPermissions();
  Future<String?> getCityFromPosition(Position position, BuildContext context);
}

class LocationServiceImpl implements LocationService {
  @override
  Future<bool> checkPermissions() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && !kIsWeb) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
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
    } catch (e) {
      debugPrint('⚠️ [LOCATION_SERVICE] Permission check error: $e');
      return false;
    }
  }

  @override
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('${AppConstants.currentPositionError}$e');
      return null;
    }
  }

  @override
  Future<String?> getCityFromPosition(Position position, BuildContext context) async {
    final locale = Localizations.maybeLocaleOf(context);
    final lang = (locale != null && locale.languageCode.isNotEmpty) ? locale.languageCode : 'ar';

    // 1. Web Reverse Geocoding (via OpenStreetMap Nominatim & BigDataCloud HTTP APIs)
    if (kIsWeb) {
      final webCity = await _reverseGeocodeHttp(position.latitude, position.longitude, lang);
      if (webCity != null && webCity.isNotEmpty) {
        return webCity;
      }
    }

    // 2. Native Geocoding Package (for Android / iOS)
    try {
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
        final city = placemark.locality ?? placemark.subAdministrativeArea ?? placemark.administrativeArea;
        if (city != null && city.trim().isNotEmpty) {
          return city.trim();
        }
      }
    } catch (e) {
      debugPrint('${AppConstants.cityFromPositionError}$e');
    }

    // Fallback to HTTP API if native geocoding fails
    return await _reverseGeocodeHttp(position.latitude, position.longitude, lang);
  }

  Future<String?> _reverseGeocodeHttp(double lat, double lng, String lang) async {
    // Attempt 1: BigDataCloud Reverse Geocoding API (Free, fast, CORS-friendly on Web)
    try {
      final url = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lng&localityLanguage=$lang',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final city = data['city'] ?? data['locality'] ?? data['principalSubdivision'];
        if (city != null && city.toString().trim().isNotEmpty) {
          return city.toString().trim();
        }
      }
    } catch (e) {
      debugPrint('⚠️ [LOCATION_SERVICE] BigDataCloud API Error: $e');
    }

    // Attempt 2: OpenStreetMap Nominatim API
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&accept-language=$lang',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'PlaySpotDashboard/1.0'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        if (address != null) {
          final city = address['city'] ??
              address['town'] ??
              address['village'] ??
              address['municipality'] ??
              address['state'] ??
              address['county'];
          if (city != null && city.toString().trim().isNotEmpty) {
            return city.toString().trim();
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [LOCATION_SERVICE] Nominatim API Error: $e');
    }

    return null;
  }
}
