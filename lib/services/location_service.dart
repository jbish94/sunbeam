import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/supabase_service.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  LocationService._();

  Position? _lastPosition;
  String? _lastAddress;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      if (!await isLocationServiceEnabled()) {
        throw Exception('Location services are disabled');
      }

      // Request permission
      if (!await requestLocationPermission()) {
        throw Exception('Location permission denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _lastPosition = position;
      return position;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Get address from coordinates
  Future<String?> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';

        if (place.street != null) address += place.street!;
        if (place.locality != null) address += ', ${place.locality!}';
        if (place.administrativeArea != null)
          address += ', ${place.administrativeArea!}';
        if (place.country != null) address += ', ${place.country!}';

        _lastAddress = address;
        return address;
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return null;
  }

  /// Save location to Supabase
  Future<String?> saveLocationToSupabase(Position position,
      {String? address}) async {
    try {
      final client = SupabaseService.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get address if not provided
      address ??= await getAddressFromCoordinates(
          position.latitude, position.longitude);

      // Extract city and country from address
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      String? city, country;
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        city = place.locality ?? place.administrativeArea;
        country = place.country;
      }

      // Mark all previous locations as not current
      await client
          .from('user_locations')
          .update({'is_current': false}).eq('user_id', user.id);

      // Insert new location
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
            'is_current': true,
            'recorded_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      print('Error saving location to Supabase: $e');
      return null;
    }
  }

  /// Get user's current location from Supabase
  Future<Map<String, dynamic>?> getCurrentLocationFromSupabase() async {
    try {
      final client = SupabaseService.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await client
          .from('user_locations')
          .select()
          .eq('user_id', user.id)
          .eq('is_current', true)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first;
      }
    } catch (e) {
      print('Error getting current location from Supabase: $e');
    }
    return null;
  }

  /// Watch position changes
  Stream<Position> watchPosition() {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  /// Get distance between two points
  double getDistanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Check if user has moved significantly
  bool hasUserMoved(Position newPosition, {double threshold = 100}) {
    if (_lastPosition == null) return true;

    double distance = getDistanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );

    return distance > threshold;
  }

  /// Get timezone for coordinates
  Future<String?> getTimezone(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        // This is a basic implementation. For production, consider using a dedicated timezone API
        String? country = placemarks.first.country;
        // Simple mapping - for production use proper timezone detection
        Map<String, String> countryTimezones = {
          'United States': 'America/New_York',
          'Canada': 'America/Toronto',
          'United Kingdom': 'Europe/London',
          'Germany': 'Europe/Berlin',
          'France': 'Europe/Paris',
          'Japan': 'Asia/Tokyo',
          'Australia': 'Australia/Sydney',
          // Add more mappings as needed
        };
        return countryTimezones[country] ?? 'UTC';
            }
    } catch (e) {
      print('Error getting timezone: $e');
    }
    return 'UTC';
  }

  /// Open device location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Open app settings for permissions
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  // Getters for last known data
  Position? get lastPosition => _lastPosition;
  String? get lastAddress => _lastAddress;
}
