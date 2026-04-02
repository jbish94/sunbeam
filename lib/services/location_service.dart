import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  // Singleton pattern
  static final instance = LocationService._internal();
  LocationService._internal();

  static const _locationTimeout = Duration(seconds: 12);

  // ---------- Permissions / settings ----------

  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  Future<void> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  Future<bool> requestLocationPermission() async {
    try {
      debugPrint('🔐 [LocationService] Checking current permission status...');
      var permission = await Geolocator.checkPermission();
      debugPrint('🔐 [LocationService] Current permission: $permission');

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        debugPrint('✅ [LocationService] Permission already granted');
        return true;
      }

      debugPrint('🔐 [LocationService] Requesting permission from user...');
      permission = await Geolocator.requestPermission();
      debugPrint('🔐 [LocationService] Permission after request: $permission');

      final granted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      debugPrint('🔐 [LocationService] Final permission granted: $granted');
      return granted;
    } catch (e) {
      debugPrint('❌ [LocationService] Error requesting location permission: $e');
      return false;
    }
  }

  // ---------- Core location helpers ----------

  Future<Position?> getCurrentLocation() async {
    try {
      debugPrint('🔍 [LocationService] Checking if location service is enabled...');
      final enabled = await isLocationServiceEnabled();
      debugPrint('🔍 [LocationService] Location service enabled: $enabled');

      if (!enabled) {
        debugPrint('❌ [LocationService] Location services are disabled');
        return null;
      }

      debugPrint('🔍 [LocationService] Requesting location permission...');
      final granted = await requestLocationPermission();
      debugPrint('🔍 [LocationService] Location permission granted: $granted');

      if (!granted) {
        debugPrint('❌ [LocationService] Location permission denied');
        return null;
      }

      debugPrint('🔍 [LocationService] Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: _locationTimeout,
      );
      debugPrint('✅ [LocationService] Position obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('❌ [LocationService] Error getting current location: $e');
      debugPrint('❌ [LocationService] Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;

      final p = placemarks.first;
      final parts = <String>[
        if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
          p.administrativeArea!,
        if (p.country != null && p.country!.isNotEmpty) p.country!,
      ];

      if (parts.isEmpty) return null;
      return parts.join(', ');
    } catch (e) {
      // geocoding uses platform channels — throws MissingPluginException on web
      if (kDebugMode) debugPrint('[LocationService] Geocoding unavailable: $e');
      return null;
    }
  }

  Future<String?> getTimezone(double lat, double lng) async {
    // Simple fallback: device timezone name.
    return DateTime.now().timeZoneName;
  }

  // ---------- Safe Supabase access ----------

  /// Try to get a Supabase client; if Supabase wasn’t initialized,
  /// this returns null instead of throwing LateInitializationError.
  SupabaseClient? get _safeSupabaseClient {
    try {
      return Supabase.instance.client;
    } catch (_) {
      // This catches LateInitializationError from Supabase internals.
      if (kDebugMode) {
        debugPrint('Supabase not initialized – skipping location save.');
      }
      return null;
    }
  }

  Future<String?> saveLocationToSupabase(Position position) async {
    final client = _safeSupabaseClient;
    if (client == null) return null;

    final user = client.auth.currentUser;
    if (user == null) return null;

    try {
      final address =
          await getAddressFromCoordinates(position.latitude, position.longitude);
      final timezone = await getTimezone(position.latitude, position.longitude);

      // Parse city and country from address string (best-effort)
      String? city;
      String? country;
      if (address != null) {
        final parts = address.split(', ');
        if (parts.length >= 1) city = parts[0];
        if (parts.length >= 3) country = parts[parts.length - 1];
      }

      // Mark all existing locations for this user as not current
      await client
          .from('user_locations')
          .update({'is_current': false})
          .eq('user_id', user.id);

      // Insert a fresh current location row
      final response = await client
          .from('user_locations')
          .insert({
            'user_id': user.id,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'altitude': position.altitude,
            'accuracy': position.accuracy,
            'address': address,
            'city': city,
            'country': country,
            'timezone': timezone,
            'is_current': true,
            'recorded_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      return response['id'] as String?;
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving location to Supabase: $e');
      return null;
    }
  }

  // ---------- Combined helper used by HomeScreen ----------

  /// Used by HomeScreen and others: get current position + address.
  /// Tries to save to Supabase, but failures are swallowed.
  Future<Map<String, dynamic>?> fetchAndSaveLocation() async {
    try {
      final position = await getCurrentLocation();
      if (position == null) {
        if (kDebugMode) {
          debugPrint('Could not get current location');
        }
        return null;
      }

      // Geocoding is non-fatal — it fails silently on web (platform channels
      // are not available). GPS coordinates are still returned to the caller.
      String? address;
      try {
        address = await getAddressFromCoordinates(
            position.latitude, position.longitude);
      } catch (e) {
        if (kDebugMode) debugPrint('[LocationService] Geocoding failed: $e');
      }

      // Try to persist, but never let errors crash the UI.
      try {
        await saveLocationToSupabase(position);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Non-fatal error saving location to Supabase: $e');
        }
      }

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
        'timezone': await getTimezone(
          position.latitude,
          position.longitude,
        ),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in fetchAndSaveLocation: $e');
      }
      return null;
    }
  }

  /// Returns the most recent location saved for the current user.
  Future<Map<String, dynamic>?> getCurrentLocationFromSupabase() async {
    final client = _safeSupabaseClient;
    if (client == null) return null;

    final user = client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await client
          .from('user_locations')
          .select('latitude, longitude, address, city, country, timezone')
          .eq('user_id', user.id)
          .eq('is_current', true)
          .order('recorded_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching location from Supabase: $e');
      return null;
    }
  }
}
