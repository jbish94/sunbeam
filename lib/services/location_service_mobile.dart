import 'package:geolocator/geolocator.dart';

class LocationService {
  static final instance = LocationService._internal();
  LocationService._internal();

  Future<Position> getCurrentLocation() async {
    await Geolocator.requestPermission();
    return await Geolocator.getCurrentPosition();
  }

  Future<String> getAddressFromCoordinates(double lat, double lon) async {
    // Placeholder if you later add geocoding
    return '$lat, $lon';
  }
}
