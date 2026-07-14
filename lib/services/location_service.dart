import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  // Singleton pattern
  static final instance = LocationService._internal();
  LocationService._internal();

  static const _locationTimeout = Duration(seconds: 12);

  /// Fixes with an error radius above this are too coarse for city-level
  /// display (a ~5 km fix can put a Mesa user in Phoenix) and trigger a
  /// best-accuracy retry.
  static const double acceptableAccuracyMeters = 1000;

  // SharedPreferences keys shared with the settings UI.
  static const String prefHighPrecisionGps = 'high_precision_gps';
  static const String prefLastFixAccuracy = 'last_fix_accuracy_m';
  static const String prefLastFixAt = 'last_fix_at';
  static const String prefManualLocation = 'manual_location';

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

  /// Passive permission check — never shows a prompt.
  Future<bool> hasLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('❌ [LocationService] Error checking permission: $e');
      return false;
    }
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

      // iOS: if the user granted only approximate location, ask for
      // temporary full accuracy — an approximate fix (~5 km) resolves to
      // the wrong city.
      await _ensurePreciseAccuracy();

      final prefs = await SharedPreferences.getInstance();
      final highPrecision = prefs.getBool(prefHighPrecisionGps) ?? true;
      final accuracy =
          highPrecision ? LocationAccuracy.best : LocationAccuracy.medium;

      debugPrint(
          '🔍 [LocationService] Getting current position (accuracy: $accuracy)...');
      var position = await _getPosition(accuracy);

      // A coarse fix in balanced mode gets one retry at best accuracy
      // before we trust it for city-level display.
      if (position != null &&
          position.accuracy > acceptableAccuracyMeters &&
          accuracy != LocationAccuracy.best) {
        debugPrint(
            '⚠️ [LocationService] Coarse fix (±${position.accuracy.round()} m) — retrying at best accuracy...');
        final retry = await _getPosition(LocationAccuracy.best);
        if (retry != null && retry.accuracy < position.accuracy) {
          position = retry;
        }
      }

      // Timed out or failed — fall back to the last known position
      // rather than returning nothing.
      position ??= await _getLastKnownPosition();

      if (position == null) {
        debugPrint('❌ [LocationService] No position available');
        return null;
      }

      if (position.accuracy > acceptableAccuracyMeters) {
        debugPrint(
            '⚠️ [LocationService] Accepting coarse fix: ±${position.accuracy.round()} m — displayed city may be approximate');
      }

      // Record fix quality so the settings screen can show real status.
      await prefs.setDouble(prefLastFixAccuracy, position.accuracy);
      await prefs.setString(
          prefLastFixAt, DateTime.now().toIso8601String());

      debugPrint(
          '✅ [LocationService] Position obtained: ${position.latitude}, ${position.longitude} (±${position.accuracy.round()} m)');
      return position;
    } catch (e) {
      debugPrint('❌ [LocationService] Error getting current location: $e');
      debugPrint('❌ [LocationService] Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  Future<Position?> _getPosition(LocationAccuracy accuracy) async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: _locationTimeout,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ [LocationService] getCurrentPosition failed: $e');
      return null;
    }
  }

  Future<Position?> _getLastKnownPosition() async {
    if (kIsWeb) return null; // not supported on web
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        debugPrint('ℹ️ [LocationService] Using last known position');
      }
      return position;
    } catch (e) {
      debugPrint('⚠️ [LocationService] getLastKnownPosition failed: $e');
      return null;
    }
  }

  /// On iOS 14+, users can grant location while disabling "Precise
  /// Location". Detect that and request temporary full accuracy so UV
  /// data matches the user's actual city.
  Future<void> _ensurePreciseAccuracy() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      var status = await Geolocator.getLocationAccuracy();
      if (status == LocationAccuracyStatus.reduced) {
        debugPrint(
            '⚠️ [LocationService] Precise Location is off — requesting temporary full accuracy...');
        status = await Geolocator.requestTemporaryFullAccuracy(
            purposeKey: 'PreciseLocation');
        if (status == LocationAccuracyStatus.reduced) {
          debugPrint(
              '⚠️ [LocationService] Still reduced accuracy — city may be approximate. Enable Precise Location in Settings for exact results.');
        }
      }
    } catch (e) {
      debugPrint('⚠️ [LocationService] Accuracy status check failed: $e');
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

  /// Formats a timezone for display. Accepts an IANA id
  /// ("America/Phoenix"), an abbreviation ("MST"), or null. Abbreviations
  /// and null fall back to the device's real UTC offset, so this never
  /// degrades to a bare "Local Time".
  static String formatTimezoneLabel(String? timezone) {
    const ianaMapping = <String, String>{
      'America/Phoenix': 'MST (GMT-7)',
      'America/Denver': 'MDT (GMT-6)',
      'America/Los_Angeles': 'PT (GMT-8/-7)',
      'America/New_York': 'ET (GMT-5/-4)',
      'America/Chicago': 'CT (GMT-6/-5)',
      'Europe/London': 'UK (GMT+0/+1)',
      'Europe/Berlin': 'CET (GMT+1/+2)',
      'Asia/Tokyo': 'JST (GMT+9)',
      'Australia/Sydney': 'AET (GMT+10/+11)',
      'UTC': 'UTC (GMT+0)',
    };
    if (timezone != null && ianaMapping.containsKey(timezone)) {
      return ianaMapping[timezone]!;
    }
    // Unmapped IANA id (manual city selection) — show it as-is; the
    // device offset would be wrong for a remote city.
    if (timezone != null && timezone.contains('/')) return timezone;

    // Abbreviation or null: pair the device's zone name with its offset.
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs();
    final minutes = offset.inMinutes.abs() % 60;
    final gmt = minutes == 0
        ? 'GMT$sign$hours'
        : 'GMT$sign$hours:${minutes.toString().padLeft(2, '0')}';
    final name = (timezone != null && timezone.isNotEmpty)
        ? timezone
        : now.timeZoneName;
    return '$name ($gmt)';
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
