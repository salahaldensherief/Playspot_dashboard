import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'request_diagnostics_client.dart';
import '../constants/app_constants.dart';

abstract class LocationService {
  Future<Position?> getCurrentPosition();
  Future<bool> checkPermissions();
  Future<String?> getCityFromPosition(Position position, BuildContext context);
}

class LocationServiceImpl implements LocationService {
  LocationServiceImpl({http.Client? client})
    : _client = client ?? RequestDiagnosticsClient();

  final http.Client _client;
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
      debugPrint(
        '⚠️ [LOCATION_SERVICE] Permission check error: ${e.runtimeType}',
      );
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
      debugPrint('${AppConstants.currentPositionError}${e.runtimeType}');
      return null;
    }
  }

  @override
  Future<String?> getCityFromPosition(
    Position position,
    BuildContext context,
  ) async {
    try {
      final locale = Localizations.maybeLocaleOf(context);
      final lang = (locale != null && locale.languageCode.isNotEmpty)
          ? locale.languageCode
          : 'ar';

      // 1. Web Reverse Geocoding (via OpenStreetMap Nominatim & BigDataCloud HTTP APIs)
      if (kIsWeb) {
        final webCity = await _reverseGeocodeHttp(
          position.latitude,
          position.longitude,
          lang,
        );
        if (webCity != null && webCity.trim().isNotEmpty) {
          return webCity.trim();
        }
      }

      // 2. Native Geocoding Package (for Android / iOS)
      try {
        if (locale != null && locale.languageCode.isNotEmpty) {
          try {
            await setLocaleIdentifier(locale.languageCode);
          } catch (e) {
            debugPrint('${AppConstants.geocodingFailed}${e.runtimeType}');
          }
        }

        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final city =
              placemark.locality ??
              placemark.subAdministrativeArea ??
              placemark.administrativeArea;
          if (city != null && city.trim().isNotEmpty) {
            return city.trim();
          }
        }
      } catch (e) {
        debugPrint('${AppConstants.cityFromPositionError}${e.runtimeType}');
      }

      // Fallback to HTTP API if native geocoding fails
      final fallbackCity = await _reverseGeocodeHttp(
        position.latitude,
        position.longitude,
        lang,
      );
      if (fallbackCity != null && fallbackCity.trim().isNotEmpty) {
        return fallbackCity.trim();
      }
      return null;
    } catch (e) {
      debugPrint(
        '⚠️ [LOCATION_SERVICE] getCityFromPosition Error: ${e.runtimeType}',
      );
      return null;
    }
  }

  Future<String?> _reverseGeocodeHttp(
    double lat,
    double lng,
    String lang,
  ) async {
    // Attempt 1: BigDataCloud Reverse Geocoding API (Free, fast, CORS-friendly on Web)
    try {
      final url = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lng&localityLanguage=$lang',
      );
      final response = await _client
          .get(url)
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map) {
          final city =
              data['city'] ?? data['locality'] ?? data['principalSubdivision'];
          if (city != null && city.toString().trim().isNotEmpty) {
            return city.toString().trim();
          }
        }
      }
    } catch (e) {
      debugPrint(
        '⚠️ [LOCATION_SERVICE] BigDataCloud API Error: ${e.runtimeType}',
      );
    }

    // Attempt 2: OpenStreetMap Nominatim API
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&accept-language=$lang',
      );
      final response = await _client
          .get(url, headers: {'User-Agent': 'PlaySpotDashboard/1.0'})
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['address'] is Map) {
          final address = data['address'] as Map;
          final city =
              address['city'] ??
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
      debugPrint('⚠️ [LOCATION_SERVICE] Nominatim API Error: ${e.runtimeType}');
    }

    return null;
  }
}
