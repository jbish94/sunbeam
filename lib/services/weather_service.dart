import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/supabase_service.dart';
import '../services/location_service.dart';

class WeatherService {
  static WeatherService? _instance;
  static WeatherService get instance => _instance ??= WeatherService._();
  WeatherService._();

  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _apiKey =
      String.fromEnvironment('OPENWEATHER_API_KEY', defaultValue: '');

  Map<String, dynamic>? _lastWeatherData;
  DateTime? _lastUpdateTime;
  static const int _cacheDurationMinutes = 10; // Cache for 10 minutes

  void _validateApiKey() {
    if (_apiKey.isEmpty) {
      throw Exception(
          'OPENWEATHER_API_KEY is not configured. Please check your env.json file.');
    }
  }

  bool _isCacheValid() {
    if (_lastWeatherData == null || _lastUpdateTime == null) return false;

    final now = DateTime.now();
    final difference = now.difference(_lastUpdateTime!);
    return difference.inMinutes < _cacheDurationMinutes;
  }

  Future<Map<String, dynamic>?> getCurrentWeather(
      double latitude, double longitude) async {
    try {
      _validateApiKey();

      if (_isCacheValid()) {
        return _lastWeatherData;
      }

      final url = Uri.parse(
          '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weatherData = _parseWeatherData(data);

        _lastWeatherData = weatherData;
        _lastUpdateTime = DateTime.now();

        return weatherData;
      } else {
        print('Weather API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching weather data: $e');
      return null;
    }
  }

  Future<double?> getUVIndex(double latitude, double longitude) async {
    try {
      _validateApiKey();

      final url = Uri.parse(
          '$_baseUrl/uvi?lat=$latitude&lon=$longitude&appid=$_apiKey');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['value'] as num?)?.toDouble();
      } else {
        print('UV Index API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching UV index: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getWeatherForecast(
      double latitude, double longitude) async {
    try {
      _validateApiKey();

      final url = Uri.parse(
          '$_baseUrl/forecast?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List forecasts = data['list'] ?? [];

        return forecasts.map((item) => _parseWeatherData(item)).toList();
      } else {
        print('Forecast API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching weather forecast: $e');
      return null;
    }
  }

  Map<String, dynamic> _parseWeatherData(Map<String, dynamic> data) {
    final main = data['main'] ?? {};
    final weather = (data['weather'] as List?)?.first ?? {};
    final wind = data['wind'] ?? {};
    final clouds = data['clouds'] ?? {};
    final sys = data['sys'] ?? {};

    return {
      'temperature': (main['temp'] as num?)?.toDouble() ?? 0.0,
      'feels_like': (main['feels_like'] as num?)?.toDouble() ?? 0.0,
      'humidity': (main['humidity'] as num?)?.toInt() ?? 0,
      'pressure': (main['pressure'] as num?)?.toDouble() ?? 0.0,
      'visibility':
          ((data['visibility'] as num?)?.toDouble() ?? 10000.0) / 1000.0,
      'uv_index': 0.0,
      'cloud_cover': (clouds['all'] as num?)?.toInt() ?? 0,
      'wind_speed': (wind['speed'] as num?)?.toDouble() ?? 0.0,
      'wind_direction': (wind['deg'] as num?)?.toInt() ?? 0,
      'weather_condition': weather['main']?.toString() ?? 'Unknown',
      'description': weather['description']?.toString() ?? 'No description',
      'icon_code': weather['icon']?.toString() ?? '01d',
      'sunrise': sys['sunrise'] != null
          ? DateTime.fromMillisecondsSinceEpoch((sys['sunrise'] as int) * 1000)
          : null,
      'sunset': sys['sunset'] != null
          ? DateTime.fromMillisecondsSinceEpoch((sys['sunset'] as int) * 1000)
          : null,
      'timestamp': DateTime.now(),
    };
  }

  Future<Map<String, dynamic>?> getCompleteWeatherData(
      double latitude, double longitude) async {
    try {
      final weatherData = await getCurrentWeather(latitude, longitude);
      if (weatherData == null) return null;

      final uvIndex = await getUVIndex(latitude, longitude);
      weatherData['uv_index'] = uvIndex ?? 0.0;

      return weatherData;
    } catch (e) {
      print('Error getting complete weather data: $e');
      return null;
    }
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
            'data_source': 'openweather',
            'recorded_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      print('Error saving weather data to Supabase: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getWeatherForCurrentLocation() async {
    try {
      final locationService = LocationService.instance;
      final position = await locationService.getCurrentLocation();
      if (position == null) {
        print('Could not get current location');
        return null;
      }

      final lat = position.latitude;
      final lng = position.longitude;

      return await getCompleteWeatherData(lat, lng);
    } catch (e) {
      print('Error getting weather for current location: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateAndSaveWeatherData() async {
    try {
      final locationService = LocationService.instance;

      final position = await locationService.getCurrentLocation();
      if (position == null) {
        print('Could not get current location');
        return null;
      }

      final locationId = await locationService.saveLocationToSupabase(position);

      final lat = position.latitude;
      final lng = position.longitude;

      final weatherData = await getCompleteWeatherData(lat, lng);
      if (weatherData == null) return null;

      // Save weather data to Supabase if we have a location ID
      if (locationId != null) {
        await saveWeatherToSupabase(weatherData, locationId);
      }

      return weatherData;
    } catch (e) {
      print('Error updating and saving weather data: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getLatestWeatherFromSupabase() async {
    try {
      final client = SupabaseService.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await client
          .from('weather_data')
          .select()
          .eq('user_id', user.id)
          .order('recorded_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        return response.first;
      }
    } catch (e) {
      print('Error getting latest weather from Supabase: $e');
    }
    return null;
  }

  String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  double convertTemperature(double celsius, {bool toFahrenheit = false}) {
    if (toFahrenheit) {
      return (celsius * 9 / 5) + 32;
    } else {
      return (celsius - 32) * 5 / 9;
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
    _lastWeatherData = null;
    _lastUpdateTime = null;
  }

  Map<String, dynamic>? get lastWeatherData => _lastWeatherData;
  DateTime? get lastUpdateTime => _lastUpdateTime;
}
