import 'dart:html' as html;

class LocationService {
  static final instance = LocationService._internal();
  LocationService._internal();

  Future<bool> isLocationServiceEnabled() async {
    // Browsers always return true if geolocation API is available
    return html.window.navigator.geolocation != null;
  }

  Future<void> requestLocationPermission() async {
    // Browser handles permission prompts automatically
  }

  Future<void> openLocationSettings() async {
    // Not available in browsers
    print('openLocationSettings() not supported on web');
  }

  Future<void> openAppSettings() async {
    // Not available in browsers
    print('openAppSettings() not supported on web');
  }

  Future<Map<String, double>> getCurrentLocation() async {
    final nav = html.window.navigator.geolocation;
    if (nav == null) throw Exception('Geolocation not supported');

    final pos = await nav.getCurrentPosition();
    return {
      'latitude': pos.coords?.latitude ?? 0.0,
      'longitude': pos.coords?.longitude ?? 0.0,
    };
  }

  Future<String> getTimezone() async {
    return DateTime.now().timeZoneName;
  }

  Future<String> getAddressFromCoordinates(double lat, double lon) async {
    // Browser version just echoes coordinates
    return '$lat, $lon';
  }

  Future<void> saveLocationToSupabase(double lat, double lon) async {
    // Stub for Supabase integration
    print('Saving location to Supabase: $lat, $lon');
  }

  Future<Map<String, double>> getCurrentLocationFromSupabase() async {
    // Stub; replace with actual Supabase logic later
    return {'latitude': 0.0, 'longitude': 0.0};
  }
}
