import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/supabase_service.dart';
import '../services/location_service.dart';

/// Weather + UV data backed by Open-Meteo (https://open-meteo.com).
/// Open-Meteo requires no API key and provides current conditions,
/// current UV index, and an hourly UV forecast in a single request.
/// Reverse geocoding uses BigDataCloud's free client endpoint.
///
/// For US locations, UV values are overridden with the EPA/NWS hourly
/// UV forecast (no key required): Open-Meteo's CAMS-derived UV can read
/// ~25% low in the US Southwest (e.g. 8.8 vs EPA's 11 for Mesa, AZ),
/// which is unsafe for an app recommending sun exposure. Open-Meteo
/// remains the fallback outside the US or if the EPA call fails.
class WeatherService {
  static WeatherService? _instance;
  static WeatherService get instance => _instance ??= WeatherService._();
  WeatherService._();

  static const String _forecastUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _reverseGeocodeUrl =
      'https://api.bigdatacloud.net/data/reverse-geocode-client';
  static const String _geocodingSearchUrl =
      'https://geocoding-api.open-meteo.com/v1/search';
  static const String _epaUvUrl =
      'https://data.epa.gov/efservice/getEnvirofactsUVHOURLY/ZIP';

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

  // ---------- EPA UV forecast (US only) ----------

  // Cached EPA hourly UV, keyed by local hour ("2026-7-14-13"). A null
  // map is also cached (non-US location or fetch failure) so every
  // refresh doesn't retry a lookup that can't succeed.
  Map<String, double>? _epaUvByHour;
  double? _epaLat;
  double? _epaLng;
  DateTime? _epaFetchedAt;
  Future<Map<String, double>?>? _inflightEpaFetch;
  static const int _epaCacheMinutes = 60;

  bool _isEpaCacheValid(double latitude, double longitude) {
    if (_epaFetchedAt == null || _epaLat == null || _epaLng == null) {
      return false;
    }
    if ((latitude - _epaLat!).abs() > 0.01 ||
        (longitude - _epaLng!).abs() > 0.01) {
      return false;
    }
    return DateTime.now().difference(_epaFetchedAt!).inMinutes <
        _epaCacheMinutes;
  }

  Future<Map<String, double>?> _getEpaUvByHour(
      double latitude, double longitude) async {
    if (_isEpaCacheValid(latitude, longitude)) return _epaUvByHour;

    final inflight = _inflightEpaFetch;
    if (inflight != null) return inflight;

    final fetch = _fetchEpaUv(latitude, longitude);
    _inflightEpaFetch = fetch;
    try {
      return await fetch;
    } finally {
      _inflightEpaFetch = null;
    }
  }

  Future<Map<String, double>?> _fetchEpaUv(
      double latitude, double longitude) async {
    _epaLat = latitude;
    _epaLng = longitude;
    _epaFetchedAt = DateTime.now();
    _epaUvByHour = null;

    final zip = await _getUsZip(latitude, longitude);
    if (zip == null) return null;

    try {
      final response = await http
          .get(Uri.parse('$_epaUvUrl/$zip/JSON'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        debugPrint('[WeatherService] EPA UV: ${response.statusCode}');
        return null;
      }
      final records = json.decode(response.body) as List;
      final byHour = <String, double>{};
      for (final record in records.whereType<Map<String, dynamic>>()) {
        final dt = _parseEpaDateTime(record['DATE_TIME'] as String?);
        final uv = (record['UV_VALUE'] as num?)?.toDouble();
        if (dt == null || uv == null) continue;
        byHour[_hourKey(dt)] = uv;
      }
      if (byHour.isEmpty) return null;
      _epaUvByHour = byHour;
      debugPrint(
          '[WeatherService] EPA UV loaded for ZIP $zip (${byHour.length} hours)');
      return byHour;
    } catch (e) {
      debugPrint('[WeatherService] EPA UV error: $e');
      return null;
    }
  }

  /// Resolves coordinates to a 5-digit US ZIP, or null outside the US.
  Future<String?> _getUsZip(double latitude, double longitude) async {
    try {
      final url = Uri.parse(_reverseGeocodeUrl).replace(queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'localityLanguage': 'en',
      });
      final response =
          await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['countryCode'] != 'US') return null;
      final postcode = ((data['postcode'] as String?) ?? '').trim();
      final zip =
          postcode.length >= 5 ? postcode.substring(0, 5) : postcode;
      return RegExp(r'^\d{5}$').hasMatch(zip) ? zip : null;
    } catch (e) {
      debugPrint('[WeatherService] ZIP lookup error: $e');
      return null;
    }
  }

  /// EPA DATE_TIME format: "Jul/14/2026 01 PM" (local to the ZIP).
  DateTime? _parseEpaDateTime(String? raw) {
    if (raw == null) return null;
    final match =
        RegExp(r'^([A-Za-z]{3})/(\d{1,2})/(\d{4})\s+(\d{1,2})\s+(AM|PM)$')
            .firstMatch(raw.trim());
    if (match == null) return null;
    const months = {
      'JAN': 1, 'FEB': 2, 'MAR': 3, 'APR': 4, 'MAY': 5, 'JUN': 6,
      'JUL': 7, 'AUG': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DEC': 12,
    };
    final month = months[match.group(1)!.toUpperCase()];
    if (month == null) return null;
    var hour = int.parse(match.group(4)!) % 12;
    if (match.group(5) == 'PM') hour += 12;
    return DateTime(
        int.parse(match.group(3)!), month, int.parse(match.group(2)!), hour);
  }

  String _hourKey(DateTime dt) =>
      '${dt.year}-${dt.month}-${dt.day}-${dt.hour}';

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
    final results = await Future.wait([
      _getForecast(latitude, longitude),
      _getEpaUvByHour(latitude, longitude),
    ]);
    final forecast = results[0] as Map<String, dynamic>?;
    final epaUv = results[1] as Map<String, double>?;
    if (forecast == null) return null;

    final weather = _parseCurrentWeather(forecast);

    // Override with the EPA value for the current hour, keyed on the
    // location's local time (from Open-Meteo) so it also works when a
    // manual location is in another timezone.
    final currentTime = DateTime.tryParse(
            (forecast['current'] as Map<String, dynamic>?)?['time']
                    as String? ??
                '') ??
        DateTime.now();
    final epaNow = epaUv?[_hourKey(currentTime)];
    if (epaNow != null) {
      weather['uv_index'] = epaNow;
      weather['uv_source'] = 'EPA';
    }
    return weather;
  }

  Future<double?> getUVIndex(double latitude, double longitude) async {
    final weather = await getCurrentWeather(latitude, longitude);
    return (weather?['uv_index'] as num?)?.toDouble();
  }

  /// Returns today's hourly UV + temperature data.
  /// Each entry has: `dt` (DateTime), `time` (String e.g. "2PM"),
  /// `uvIndex` (double), `temp` (int, °F).
  Future<List<Map<String, dynamic>>?> getHourlyUvForecast(
      double latitude, double longitude) async {
    final results = await Future.wait([
      _getForecast(latitude, longitude),
      _getEpaUvByHour(latitude, longitude),
    ]);
    final forecast = results[0] as Map<String, dynamic>?;
    final epaUv = results[1] as Map<String, double>?;
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
        // EPA/NWS value wins when available (US locations); both series
        // are in the location's local time so the hour keys line up.
        final openMeteoUv = (uvValues[i] as num?)?.toDouble() ?? 0.0;
        result.add({
          'dt': dt,
          'time': _formatHour(dt),
          'uvIndex': epaUv?[_hourKey(dt)] ?? openMeteoUv,
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

        // Prefer 'locality' (the actual place, e.g. "Mesa") over 'city'
        // (often the nearest major city, e.g. "Phoenix") so suburbs
        // aren't mislabeled with the metro's principal city.
        final city = nonEmpty('locality') ?? nonEmpty('city');
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

  /// Searches for places by name using Open-Meteo's free geocoding API
  /// (no key required, works on web). Returns matches with display name,
  /// coordinates, and IANA timezone — used for the manual location
  /// override in Location Settings.
  Future<List<Map<String, dynamic>>> searchLocations(String query,
      {int count = 5}) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];
    try {
      final url = Uri.parse(_geocodingSearchUrl).replace(queryParameters: {
        'name': trimmed,
        'count': count.toString(),
        'language': 'en',
        'format': 'json',
      });
      final response =
          await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        debugPrint(
            '[WeatherService] Geocoding search: ${response.statusCode}');
        return [];
      }
      final data = json.decode(response.body) as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? [];
      return results
          .whereType<Map<String, dynamic>>()
          .where((r) =>
              r['name'] != null &&
              r['latitude'] != null &&
              r['longitude'] != null)
          .map((r) => {
                'name': r['name'] as String,
                'region': r['admin1'] as String?,
                'country': r['country'] as String?,
                'latitude': (r['latitude'] as num).toDouble(),
                'longitude': (r['longitude'] as num).toDouble(),
                'timezone': r['timezone'] as String?,
              })
          .toList();
    } catch (e) {
      debugPrint('[WeatherService] searchLocations error: $e');
      return [];
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
