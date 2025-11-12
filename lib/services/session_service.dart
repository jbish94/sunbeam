import '../services/supabase_service.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';

class SessionService {
  static SessionService? _instance;
  static SessionService get instance => _instance ??= SessionService._();
  SessionService._();

  String? _currentSessionId;
  DateTime? _sessionStartTime;
  Map<String, dynamic>? _sessionStartWeather;
  String? _sessionLocationId;

  /// Start a new sun exposure session
  Future<String?> startSession({
    int? moodBefore,
    int? energyBefore,
    List<String>? protectionUsed,
    String? notes,
  }) async {
    try {
      final client = SupabaseService.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get current location and weather
      final locationService = LocationService.instance;
      final weatherService = WeatherService.instance;

      final position = await locationService.getCurrentLocation();
      if (position == null) {
        throw Exception('Could not get current location');
      }

      // Save current location
      final locationId = await locationService.saveLocationToSupabase(position);
      if (locationId == null) {
        throw Exception('Could not save location');
      }

      // Get current weather data
      final weatherData = await weatherService.getCompleteWeatherData(
          position.latitude, position.longitude);
      if (weatherData == null) {
        throw Exception('Could not get weather data');
      }

      // Save weather data
      final weatherId =
          await weatherService.saveWeatherToSupabase(weatherData, locationId);

      final startTime = DateTime.now();

      // Create session in database
      final response = await client
          .from('sun_sessions')
          .insert({
            'user_id': user.id,
            'location_id': locationId,
            'weather_id': weatherId,
            'start_time': startTime.toIso8601String(),
            'uv_index_start': weatherData['uv_index'],
            'temperature_start': weatherData['temperature'],
            'mood_before': moodBefore,
            'energy_before': energyBefore,
            'protection_used': protectionUsed,
            'notes': notes,
            'status': 'active',
          })
          .select('id')
          .single();

      _currentSessionId = response['id'] as String;
      _sessionStartTime = startTime;
      _sessionStartWeather = weatherData;
      _sessionLocationId = locationId;

      return _currentSessionId;
    } catch (e) {
      print('Error starting session: $e');
      return null;
    }
  }

  /// End the current session
  Future<bool> endSession({
    int? moodAfter,
    int? energyAfter,
    String? additionalNotes,
  }) async {
    try {
      if (_currentSessionId == null) {
        throw Exception('No active session to end');
      }

      final client = SupabaseService.instance.client;
      final endTime = DateTime.now();

      // Get current weather for end conditions
      final weatherService = WeatherService.instance;
      final position = await LocationService.instance.getCurrentLocation();

      Map<String, dynamic>? endWeather;
      if (position != null) {
        endWeather = await weatherService.getCompleteWeatherData(
            position.latitude, position.longitude);
      }

      // Calculate duration
      final duration = _sessionStartTime != null
          ? endTime.difference(_sessionStartTime!).inMinutes
          : null;

      // Calculate average UV index
      final startUV = _sessionStartWeather?['uv_index']?.toDouble() ?? 0.0;
      final endUV = endWeather?['uv_index']?.toDouble() ?? startUV;
      final avgUV = (startUV + endUV) / 2;

      // Update session in database
      Map<String, dynamic> updateData = {
        'end_time': endTime.toIso8601String(),
        'duration_minutes': duration,
        'status': 'completed',
        'uv_index_avg': avgUV,
      };

      if (endWeather != null) {
        updateData.addAll({
          'uv_index_end': endUV,
          'temperature_end': endWeather['temperature'],
        });
      }

      if (moodAfter != null) updateData['mood_after'] = moodAfter;
      if (energyAfter != null) updateData['energy_after'] = energyAfter;
      if (additionalNotes != null) updateData['notes'] = additionalNotes;

      await client
          .from('sun_sessions')
          .update(updateData)
          .eq('id', _currentSessionId!);

      // Clear current session data
      _clearSessionData();

      return true;
    } catch (e) {
      print('Error ending session: $e');
      return false;
    }
  }

  /// Pause the current session
  Future<bool> pauseSession() async {
    try {
      if (_currentSessionId == null) {
        throw Exception('No active session to pause');
      }

      final client = SupabaseService.instance.client;

      await client
          .from('sun_sessions')
          .update({'status': 'paused'}).eq('id', _currentSessionId!);

      return true;
    } catch (e) {
      print('Error pausing session: $e');
      return false;
    }
  }

  /// Resume a paused session
  Future<bool> resumeSession() async {
    try {
      if (_currentSessionId == null) {
        throw Exception('No session to resume');
      }

      final client = SupabaseService.instance.client;

      await client
          .from('sun_sessions')
          .update({'status': 'active'}).eq('id', _currentSessionId!);

      return true;
    } catch (e) {
      print('Error resuming session: $e');
      return false;
    }
  }

  /// Cancel the current session
  Future<bool> cancelSession() async {
    try {
      if (_currentSessionId == null) {
        throw Exception('No active session to cancel');
      }

      final client = SupabaseService.instance.client;

      await client.from('sun_sessions').update({
        'status': 'cancelled',
        'end_time': DateTime.now().toIso8601String(),
      }).eq('id', _currentSessionId!);

      _clearSessionData();

      return true;
    } catch (e) {
      print('Error cancelling session: $e');
      return false;
    }
  }

  /// Get current active session
  Future<Map<String, dynamic>?> getCurrentSession() async {
    try {
      final client = SupabaseService.instance.client;
      final user = client.auth.currentUser;

      if (user == null) return null;

      final response = await client
          .from('sun_sessions')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'active')
          .order('start_time', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        final session = response.first;
        _currentSessionId = session['id'];
        _sessionStartTime = DateTime.parse(session['start_time']);
        return session;
      }
    } catch (e) {
      print('Error getting current session: $e');
    }
    return null;
  }

  /// Get user's session history
  Future<List<Map<String, dynamic>>> getSessionHistory({
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final client = SupabaseService.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      var query = client
          .from('sun_sessions')
          .select()
          .eq('user_id', user.id)
          .order('start_time', ascending: false)
          .limit(limit);

      if (startDate != null) {
        query = query.gte('start_time', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('start_time', endDate.toIso8601String());
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting session history: $e');
      return [];
    }
  }

  /// Get session statistics
  Future<Map<String, dynamic>> getSessionStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final sessions = await getSessionHistory(
        limit: 1000,
        startDate: startDate,
        endDate: endDate,
      );

      final completedSessions =
          sessions.where((s) => s['status'] == 'completed').toList();

      int totalSessions = completedSessions.length;
      int totalMinutes = 0;
      double totalUVExposure = 0;
      int moodImprovements = 0;
      int energyImprovements = 0;

      for (final session in completedSessions) {
        totalMinutes += (session['duration_minutes'] as int?) ?? 0;
        totalUVExposure += (session['uv_index_avg'] as num?)?.toDouble() ?? 0;

        final moodBefore = session['mood_before'] as int?;
        final moodAfter = session['mood_after'] as int?;
        if (moodBefore != null && moodAfter != null && moodAfter > moodBefore) {
          moodImprovements++;
        }

        final energyBefore = session['energy_before'] as int?;
        final energyAfter = session['energy_after'] as int?;
        if (energyBefore != null &&
            energyAfter != null &&
            energyAfter > energyBefore) {
          energyImprovements++;
        }
      }

      return {
        'total_sessions': totalSessions,
        'total_minutes': totalMinutes,
        'average_session_minutes':
            totalSessions > 0 ? totalMinutes / totalSessions : 0,
        'total_uv_exposure': totalUVExposure,
        'average_uv_exposure':
            totalSessions > 0 ? totalUVExposure / totalSessions : 0,
        'mood_improvement_rate':
            totalSessions > 0 ? moodImprovements / totalSessions : 0,
        'energy_improvement_rate':
            totalSessions > 0 ? energyImprovements / totalSessions : 0,
      };
    } catch (e) {
      print('Error getting session stats: $e');
      return {};
    }
  }

  /// Get sessions for a specific date range
  Future<List<Map<String, dynamic>>> getSessionsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await getSessionHistory(
      startDate: startDate,
      endDate: endDate,
      limit: 1000,
    );
  }

  /// Update session notes
  Future<bool> updateSessionNotes(String sessionId, String notes) async {
    try {
      final client = SupabaseService.instance.client;

      await client
          .from('sun_sessions')
          .update({'notes': notes}).eq('id', sessionId);

      return true;
    } catch (e) {
      print('Error updating session notes: $e');
      return false;
    }
  }

  /// Clear current session data
  void _clearSessionData() {
    _currentSessionId = null;
    _sessionStartTime = null;
    _sessionStartWeather = null;
    _sessionLocationId = null;
  }

  // Getters
  String? get currentSessionId => _currentSessionId;
  DateTime? get sessionStartTime => _sessionStartTime;
  bool get hasActiveSession => _currentSessionId != null;
}
