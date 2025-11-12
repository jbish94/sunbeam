import 'dart:html' as html;

class LocationService {
  static final instance = LocationService._internal();
  LocationService._internal();

  Future<bool> isLocationServiceEnabled() async =>
      html.window.navigator.geolocation != null;

  Future<bool> requestLocationPermission() async => true;

  Future<void> openLocationSettings() async =>
      print('openLocationSettings() not supported on web');
  Future<void> openAppSettings() async =>
      print('openAppSettings() not supported on web');

  Future<Map<String, dynamic>> getCurrentLocation() async {
    final nav = html.window.navigator.geolocation;
    if (nav == null) throw Exception('Geolocation not supported');

    final pos = await nav.getCurrentPosition();
    final lat = (pos.coords?.latitude ?? 0).toDouble();
    final lon = (pos.coords?.longitude ?? 0).toDouble();
    final address = '$lat, $lon';
    return {'latitude': lat, 'longitude': lon, 'address': address};
  }

  Future<String> getAddressFromCoordinates(double lat, double lon) async {
    return '$lat, $lon';
  }

  Future<String> getTimezone([double? lat, double? lon]) async =>
      DateTime.now().timeZoneName;

  Future<bool> saveLocationToSupabase(dynamic position) async {
    final lat = (position['latitude'] ?? 0).toDouble();
    final lon = (position['longitude'] ?? 0).toDouble();
    print('Saving location to Supabase: $lat, $lon');
    return true;
  }

  Future<Map<String, dynamic>> getCurrentLocationFromSupabase() async {
    return {'latitude': 0.0, 'longitude': 0.0, 'address': 'Unknown'};
  }
}
