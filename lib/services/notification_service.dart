import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Local (on-device) notifications: optimal sun window alerts and
/// missed-session reminders. Not supported on web — every method is a
/// silent no-op there.
class NotificationService {
  static final instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Stable notification ids so rescheduling replaces instead of stacking.
  static const int _idOptimalWindow = 1001;
  static const int _idMissedSession = 1002;

  // Preference keys shared with the profile screen toggles.
  static const String prefOptimalWindowAlerts = 'optimal_window_alerts';
  static const String prefMissedSessionReminders = 'missed_session_reminders';
  static const String prefEducationalContent = 'educational_content';

  /// Minutes before the sun window opens that the alert fires.
  static const int optimalWindowLeadMinutes = 30;

  Future<void> init() async {
    if (kIsWeb || _initialized) return;
    try {
      tz_data.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (e) {
        // tz.local falls back to UTC; scheduling still works but may be
        // offset — better than failing init entirely.
        debugPrint('[NotificationService] Timezone detection failed: $e');
      }

      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Permissions are requested explicitly when the user enables a
          // notification toggle, not at app launch.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(settings: settings);
      _initialized = true;
      debugPrint('[NotificationService] Initialized');
    } catch (e) {
      debugPrint('[NotificationService] Init failed: $e');
    }
  }

  /// Asks the OS for notification permission (Android 13+ / iOS).
  /// Returns true when granted (or not required on this platform).
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    await init();
    if (!_initialized) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      return true;
    } catch (e) {
      debugPrint('[NotificationService] Permission request failed: $e');
      return false;
    }
  }

  /// Schedules the "sun window opening soon" alert. Replaces any
  /// previously scheduled one. No-op when the toggle is off or the
  /// window (minus lead time) is already past.
  Future<void> scheduleOptimalWindowAlert({
    required DateTime windowStart,
    required String windowLabel,
  }) async {
    if (kIsWeb) return;
    await init();
    if (!_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(prefOptimalWindowAlerts) ?? true)) return;

    final fireAt = windowStart
        .subtract(const Duration(minutes: optimalWindowLeadMinutes));
    if (!fireAt.isAfter(DateTime.now())) return;

    try {
      await _plugin.zonedSchedule(
        id: _idOptimalWindow,
        title: 'Your Sun Window Opens Soon ☀️',
        body: 'Optimal UV conditions $windowLabel — time to get ready.',
        scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'sun_window',
            'Sun Window Alerts',
            channelDescription:
                'Alerts before your optimal sun exposure window opens',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint(
          '[NotificationService] Sun window alert scheduled for $fireAt');
    } catch (e) {
      debugPrint('[NotificationService] Failed to schedule window alert: $e');
    }
  }

  Future<void> cancelOptimalWindowAlert() async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancel(id: _idOptimalWindow);
  }

  /// Schedules today's 12:30 PM "no session logged yet" reminder.
  /// Call when the app opens with no sessions logged today; cancelled
  /// when a session is logged. No-op if the toggle is off or it's
  /// already past 12:30.
  Future<void> scheduleMissedSessionReminder() async {
    if (kIsWeb) return;
    await init();
    if (!_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(prefMissedSessionReminders) ?? true)) return;

    final now = DateTime.now();
    final fireAt = DateTime(now.year, now.month, now.day, 12, 30);
    if (!fireAt.isAfter(now)) return;

    try {
      await _plugin.zonedSchedule(
        id: _idMissedSession,
        title: 'No Sun Session Yet Today',
        body:
            'There may still be time — check today\'s UV conditions for a short session.',
        scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'session_reminders',
            'Session Reminders',
            channelDescription:
                'Gentle reminders when no sun session has been logged',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint(
          '[NotificationService] Missed-session reminder scheduled for $fireAt');
    } catch (e) {
      debugPrint('[NotificationService] Failed to schedule reminder: $e');
    }
  }

  Future<void> cancelMissedSessionReminder() async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancel(id: _idMissedSession);
  }
}
