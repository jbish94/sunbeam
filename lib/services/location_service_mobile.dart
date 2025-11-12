import 'package:geolocator/geolocator.dart';

class LocationService {
  static final instance = LocationService._internal();
  LocationService._internal();

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<Position> getCurrentLocation() async {
    await Geolocator.requestPermission();
    return await Geolocator.getCurrentPosition();
  }

  Future<String> getTimezone() async {
    // Stubbed; mobile version can later use native APIs or packages
    return DateTime.now().timeZoneName;
  }

  Future<String> getAddressFromCoordinates(double lat, double lon) async {
    // Placeholder; add real reverse geocoding later if needed
    return '$lat, $lon';
  }

  Future<void> saveLocationToSupabase(double lat, double lon) async {
    // Stub for Supabase integration
    print('Saving location to Supabase: $lat, $lon');
  }

  Future<Map<String, double>> getCurrentLocationFromSupabase() async {
    // Stub; replace with actual Supabase call later
    return {'latitude': 0.0, 'longitude': 0.0};
  }
}
