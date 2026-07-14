import 'package:flutter/foundation.dart';
import '../services/supabase_service.dart';

/// Sun session persistence. Sessions are logged retroactively from
/// LogSessionScreen; live start/stop tracking was removed as dead code
/// (git history has it if a real-time session feature is built later).
class SessionService {
  static SessionService? _instance;
  static SessionService get instance => _instance ??= SessionService._();
  SessionService._();

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

      var filterQuery = client
          .from('sun_sessions')
          .select()
          .eq('user_id', user.id);

      if (startDate != null) {
        filterQuery = filterQuery.gte('start_time', startDate.toIso8601String());
      }

      if (endDate != null) {
        filterQuery = filterQuery.lte('start_time', endDate.toIso8601String());
      }

      final response = await filterQuery
          .order('start_time', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting session history: $e');
      return [];
    }
  }

  /// Log a manually-entered past session (used by LogSessionScreen).
  /// Inserts the completed record in one go.
  Future<String?> logSession({
    required DateTime startTime,
    required int durationMinutes,
    required List<String> protectionUsed,
    int? moodBefore,
    int? energyBefore,
    String? notes,
  }) async {
    try {
      final client = SupabaseService.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final endTime = startTime.add(Duration(minutes: durationMinutes));

      final response = await client
          .from('sun_sessions')
          .insert({
            'user_id': user.id,
            'start_time': startTime.toIso8601String(),
            'end_time': endTime.toIso8601String(),
            'duration_minutes': durationMinutes,
            'protection_used': protectionUsed,
            'mood_before': moodBefore,
            'energy_before': energyBefore,
            'notes': notes?.isNotEmpty == true ? notes : null,
            'status': 'completed',
          })
          .select('id')
          .single();

      return response['id'] as String?;
    } catch (e) {
      debugPrint('Error logging session: $e');
      return null;
    }
  }
}
