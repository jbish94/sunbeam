import 'dart:html' as html;

class PositionData {
  final double latitude;
  final double longitude;
  final String address;
  PositionData(this.latitude, this.longitude, this.address);
}

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

  Future<PositionData> getCurrentLocation() async {
    final nav = html.window.navigator.geolocation;
    if (nav == null) throw Exception('Geolocation not supported');
    final pos = await nav.getCurrentPosition();
    final lat = (pos.coords?.latitude ?? 0).toDouble();
    final lon = (pos.coords?.longitude ?? 0).toDouble();
    final address = '$lat, $lon';
    return PositionData(lat, lon, address);
  }

  Future<String> getAddressFromCoordinates(double lat, double lon) async {
    return '$lat, $lon';
  }

  Future<String> getTimezone([double? lat, double? lon]) async =>
      DateTime.now().timeZoneName;

  Future<void> saveLocationToSupabase(PositionData position) async {
    print('Saving location to Supabase: ${position.latitude}, ${position.longitude}');
  }

  Future<PositionData> getCurrentLocationFromSupabase() async {
    return PositionData(0.0, 0.0, 'Unknown');
  }
}
