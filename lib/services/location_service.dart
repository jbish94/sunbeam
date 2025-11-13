import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  static const _locationTimeout = Duration(seconds: 12);

  final SupabaseClient _supabase = Supabase.instance.client;

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
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return true;
    }

    permission = await Geolocator.requestPermission();

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Returns null if service/permission fails.
  Future<Position?> getCurrentLocation() async {
    final enabled = await isLocationServiceEnabled();
    if (!enabled) {
      return null;
    }

    final granted = await requestLocationPermission();
    if (!granted) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: _locationTimeout,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
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
  }

  /// Simple fallback: device timezone name.
  Future<String?> getTimezone(double lat, double lng) async {
    return DateTime.now().timeZoneName;
  }

  /// Save latest location for user into Supabase.
  Future<void> saveLocationToSupabase(Position position) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      // Not logged in, nothing to save.
      return;
    }

    await _supabase.from('user_locations').upsert({
      'user_id': user.id,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Used by HomeScreen and others: get current position + address + timezone.
  Future<Map<String, dynamic>?> fetchAndSaveLocation() async {
    final position = await getCurrentLocation();
    if (position == null) return null;

    final address =
        await getAddressFromCoordinates(position.latitude, position.longitude);
    final timezone =
        await getTimezone(position.latitude, position.longitude);

    // Optionally save in Supabase as well:
    await saveLocationToSupabase(position);

    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'address': address,
      'timezone': timezone,
    };
  }

  /// Stub for callers that may expect this; implement later if needed.
  Future<Map<String, dynamic>?> getCurrentLocationFromSupabase() async {
    return null;
  }
}
