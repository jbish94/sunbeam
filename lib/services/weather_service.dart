import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/supabase_service.dart';
import '../services/location_service.dart';

/// Weather + UV data backed by Open-Meteo (https://open-meteo.com).
/// Open-Meteo requires no API key and provides current conditions,
/// current UV index, and an hourly UV forecast in a single request.
/// Reverse geocoding uses BigDataCloud's free client endpoint.
class WeatherService {
  static WeatherService? _instance;
  static WeatherService get instance => _instance ??= WeatherService._();
  WeatherService._();

  static const String _forecastUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _reverseGeocodeUrl =
      'https://api.bigdatacloud.net/data/reverse-geocode-client';

  // Raw forecast response cache (one network call serves current weather,
  // UV index, and the hourly chart).
  Map<String, dynamic>? _lastForecast;
  Map<String, dynamic>? _lastWeatherData;
  double? _lastLat;
  double? _lastLng;
  DateTime? _lastUpdateTime;
  Future<Map<String, dynamic>?>? _inflightFetch;
  static const int _cacheDurationMinutes = 10;

  bool _isCacheValid(double latitude, double longitude) {
    if (_lastForecast == null || _lastUpdateTime == null) return false;
    if (_lastLat == null || _lastLng == null) return false;
    // ~1km tolerance so small GPS jitter still hits the cache.
    if ((latitude - _lastLat!).abs() > 0.01 ||
        (longitude - _lastLng!).abs() > 0.01) {
      return false;
    }
    return DateTime.now().difference(_lastUpdateTime!).inMinutes <
        _cacheDurationMinutes;
  }

  /// Fetches (or returns cached) raw Open-Meteo forecast data.
  /// Concurrent callers share a single in-flight request.
  Future<Map<String, dynamic>?> _getForecast(
      double latitude, double longitude) async {
    if (_isCacheValid(latitude, longitude)) return _lastForecast;

    final inflight = _inflightFetch;
    if (inflight != null) return inflight;

    final fetch = _fetchForecast(latitude, longitude);
    _inflightFetch = fetch;
    try {
      return await fetch;
    } finally {
      _inflightFetch = null;
    }
  }

  Future<Map<String, dynamic>?> _fetchForecast(
      double latitude, double longitude) async {
    try {
      final url = Uri.parse(_forecastUrl).replace(queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,'
            'weather_code,cloud_cover,wind_speed_10m,wind_direction_10m,'
            'surface_pressure,uv_index',
        'hourly': 'uv_index,temperature_2m,visibility',
        'daily': 'sunrise,sunset',
        'temperature_unit': 'fahrenheit',
        'wind_speed_unit': 'mph',
        'timezone': 'auto',
        'forecast_days': '1',
      });

      final response =
          await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _lastForecast = data;
        _lastWeatherData = _parseCurrentWeather(data);
        _lastLat = latitude;
        _lastLng = longitude;
        _lastUpdateTime = DateTime.now();
        return data;
      }
      debugPrint(
          '[WeatherService] Open-Meteo error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('[WeatherService] Error fetching forecast: $e');
      return null;
    }
  }

  Map<String, dynamic> _parseCurrentWeather(Map<String, dynamic> data) {
    final current = (data['current'] as Map<String, dynamic>?) ?? {};
    final daily = (data['daily'] as Map<String, dynamic>?) ?? {};
    final weatherCode = (current['weather_code'] as num?)?.toInt() ?? 0;
    final condition = _wmoCondition(weatherCode);

    DateTime? parseDailyTime(String key) {
      final list = daily[key] as List?;
      if (list == null || list.isEmpty) return null;
      return DateTime.tryParse(list.first as String);
    }

    return {
      // Temperatures are °F (requested via temperature_unit=fahrenheit).
      'temperature': (current['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      'feels_like':
          (current['apparent_temperature'] as num?)?.toDouble() ?? 0.0,
      'humidity': (current['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      'pressure': (current['surface_pressure'] as num?)?.toDouble() ?? 0.0,
      'visibility': _currentVisibilityKm(data) ?? 10.0,
      'uv_index': (current['uv_index'] as num?)?.toDouble() ?? 0.0,
      'cloud_cover': (current['cloud_cover'] as num?)?.toInt() ?? 0,
      'wind_speed': (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
      'wind_direction': (current['wind_direction_10m'] as num?)?.toInt() ?? 0,
      'weather_condition': condition['condition'],
      'description': condition['description'],
      'icon_code': condition['icon'],
      'sunrise': parseDailyTime('sunrise'),
      'sunset': parseDailyTime('sunset'),
      'timestamp': DateTime.now(),
    };
  }

  /// Visibility (km) for the current hour, from the hourly series.
  double? _currentVisibilityKm(Map<String, dynamic> data) {
    try {
      final hourly = (data['hourly'] as Map<String, dynamic>?) ?? {};
      final times = (hourly['time'] as List?)?.cast<String>();
      final visibility = (hourly['visibility'] as List?);
      if (times == null || visibility == null) return null;
      final now = DateTime.now();
      for (var i = 0; i < times.length && i < visibility.length; i++) {
        final t = DateTime.tryParse(times[i]);
        if (t != null && t.hour == now.hour) {
          return ((visibility[i] as num?)?.toDouble() ?? 10000.0) / 1000.0;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Maps WMO weather codes (Open-Meteo) to a coarse condition,
  /// human description, and an OpenWeather-style icon code.
  Map<String, String> _wmoCondition(int code) {
    if (code == 0) {
      return {'condition': 'Clear', 'description': 'clear sky', 'icon': '01d'};
    }
    if (code == 1) {
      return {
        'condition': 'Clear',
        'description': 'mainly clear',
        'icon': '02d'
      };
    }
    if (code == 2) {
      return {
        'condition': 'Clouds',
        'description': 'partly cloudy',
        'icon': '03d'
      };
    }
    if (code == 3) {
      return {'condition': 'Clouds', 'description': 'overcast', 'icon': '04d'};
    }
    if (code == 45 || code == 48) {
      return {'condition': 'Fog', 'description': 'fog', 'icon': '50d'};
    }
    if (code >= 51 && code <= 57) {
      return {'condition': 'Drizzle', 'description': 'drizzle', 'icon': '09d'};
    }
    if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) {
      return {'condition': 'Rain', 'description': 'rain', 'icon': '10d'};
    }
    if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
      return {'condition': 'Snow', 'description': 'snow', 'icon': '13d'};
    }
    if (code >= 95) {
      return {
        'condition': 'Thunderstorm',
        'description': 'thunderstorm',
        'icon': '11d'
      };
    }
    return {'condition': 'Clouds', 'description': 'cloudy', 'icon': '03d'};
  }

  Future<Map<String, dynamic>?> getCurrentWeather(
      double latitude, double longitude) async {
    final forecast = await _getForecast(latitude, longitude);
    if (forecast == null) return null;
    return _parseCurrentWeather(forecast);
  }

  Future<double?> getUVIndex(double latitude, double longitude) async {
    final forecast = await _getForecast(latitude, longitude);
    final current = forecast?['current'] as Map<String, dynamic>?;
    return (current?['uv_index'] as num?)?.toDouble();
  }

  /// Returns today's hourly UV + temperature data.
  /// Each entry has: `dt` (DateTime), `time` (String e.g. "2PM"),
  /// `uvIndex` (double), `temp` (int, °F).
  Future<List<Map<String, dynamic>>?> getHourlyUvForecast(
      double latitude, double longitude) async {
    final forecast = await _getForecast(latitude, longitude);
    if (forecast == null) return null;

    try {
      final hourly = (forecast['hourly'] as Map<String, dynamic>?) ?? {};
      final times = (hourly['time'] as List?)?.cast<String>() ?? [];
      final uvValues = (hourly['uv_index'] as List?) ?? [];
      final temps = (hourly['temperature_2m'] as List?) ?? [];

      final result = <Map<String, dynamic>>[];
      for (var i = 0;
          i < times.length && i < uvValues.length && i < temps.length;
          i++) {
        final dt = DateTime.tryParse(times[i]);
        if (dt == null) continue;
        result.add({
          'dt': dt,
          'time': _formatHour(dt),
          'uvIndex': (uvValues[i] as num?)?.toDouble() ?? 0.0,
          'temp': ((temps[i] as num?)?.toDouble() ?? 0.0).round(),
        });
      }
      return result.isEmpty ? null : result;
    } catch (e) {
      debugPrint('[WeatherService] getHourlyUvForecast error: $e');
      return null;
    }
  }

  String _formatHour(DateTime dt) {
    final h = dt.hour;
    if (h == 0) return '12AM';
    if (h < 12) return '${h}AM';
    if (h == 12) return '12PM';
    return '${h - 12}PM';
  }

  /// Reverse-geocodes coordinates using BigDataCloud's free client API
  /// (no key required, works on web). Returns "City, State" or
  /// "City, Country".
  Future<String?> getLocationName(double lat, double lng) async {
    try {
      final url = Uri.parse(_reverseGeocodeUrl).replace(queryParameters: {
        'latitude': lat.toString(),
        'longitude': lng.toString(),
        'localityLanguage': 'en',
      });
      final response =
          await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        String? nonEmpty(String key) {
          final v = data[key] as String?;
          return (v != null && v.isNotEmpty) ? v : null;
        }

        final city = nonEmpty('city') ?? nonEmpty('locality');
        final region = nonEmpty('principalSubdivision');
        final country = nonEmpty('countryName');
        if (city != null && region != null) return '$city, $region';
        if (city != null && country != null) return '$city, $country';
        return city ?? region;
      }
      debugPrint('[WeatherService] Reverse geocode: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('[WeatherService] getLocationName error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCompleteWeatherData(
      double latitude, double longitude) async {
    return getCurrentWeather(latitude, longitude);
  }

  Future<String?> saveWeatherToSupabase(
    Map<String, dynamic> weatherData,
    String locationId,
  ) async {
    try {
      final client = SupabaseService.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await client
          .from('weather_data')
          .insert({
            'user_id': user.id,
            'location_id': locationId,
            'temperature': weatherData['temperature'],
            'feels_like': weatherData['feels_like'],
            'humidity': weatherData['humidity'],
            'pressure': weatherData['pressure'],
            'visibility': weatherData['visibility'],
            'uv_index': weatherData['uv_index'],
            'cloud_cover': weatherData['cloud_cover'],
            'wind_speed': weatherData['wind_speed'],
            'wind_direction': weatherData['wind_direction'],
            'weather_condition': weatherData['weather_condition'],
            'description': weatherData['description'],
            'icon_code': weatherData['icon_code'],
            'sunrise': weatherData['sunrise']?.toIso8601String(),
            'sunset': weatherData['sunset']?.toIso8601String(),
            'data_source': 'open-meteo',
            'recorded_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('Error saving weather data to Supabase: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getWeatherForCurrentLocation() async {
    try {
      final position = await LocationService.instance.getCurrentLocation();
      if (position == null) {
        debugPrint('Could not get current location');
        return null;
      }
      return await getCompleteWeatherData(
          position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error getting weather for current location: $e');
      return null;
    }
  }

  String getUVSafetyLevel(double uvIndex) {
    if (uvIndex <= 2) return 'Low';
    if (uvIndex <= 5) return 'Moderate';
    if (uvIndex <= 7) return 'High';
    if (uvIndex <= 10) return 'Very High';
    return 'Extreme';
  }

  void clearCache() {
    _lastForecast = null;
    _lastWeatherData = null;
    _lastLat = null;
    _lastLng = null;
    _lastUpdateTime = null;
  }

  Map<String, dynamic>? get lastWeatherData => _lastWeatherData;
  DateTime? get lastUpdateTime => _lastUpdateTime;
}
