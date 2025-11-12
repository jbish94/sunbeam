import 'package:geolocator/geolocator.dart';

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
      await Geolocator.isLocationServiceEnabled();

  Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> openLocationSettings() async => Geolocator.openLocationSettings();
  Future<void> openAppSettings() async => Geolocator.openAppSettings();

  Future<PositionData> getCurrentLocation() async {
    await Geolocator.requestPermission();
    final pos = await Geolocator.getCurrentPosition();
    final lat = pos.latitude;
    final lon = pos.longitude;
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
