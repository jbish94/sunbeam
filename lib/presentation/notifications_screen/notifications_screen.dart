import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/session_service.dart';
import '../../services/weather_service.dart';
import './widgets/empty_notifications_widget.dart';
import './widgets/notification_group_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  /// Builds notifications from real app state: current UV conditions and
  /// the user's session history vs. their goals. IDs are stable per day so
  /// read/dismissed state persists across visits.
  Future<void> _loadNotifications() async {
    final notifications = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final dayKey =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    try {
      // Current UV conditions (uses the cached value fetched by Home).
      final weather = WeatherService.instance.lastWeatherData;
      final uvIndex = (weather?['uv_index'] as num?)?.toDouble();
      if (uvIndex != null && uvIndex >= 8) {
        notifications.add({
          'id': 'uv_high_$dayKey',
          'type': 'weather_alert',
          'title': 'High UV Alert',
          'description':
              'UV index is ${uvIndex.toStringAsFixed(0)} right now. Limit time in direct sun and use protection.',
          'timestamp': now,
          'isRead': false,
          'icon': 'warning_amber',
          'iconColor': Colors.red,
        });
      } else if (uvIndex != null && uvIndex >= 3 && uvIndex <= 6) {
        notifications.add({
          'id': 'uv_window_$dayKey',
          'type': 'sun_window',
          'title': 'Moderate UV Conditions',
          'description':
              'UV index is ${uvIndex.toStringAsFixed(0)} — a reasonable window for a short, protected session.',
          'timestamp': now,
          'isRead': false,
          'icon': 'wb_sunny',
          'iconColor': Colors.orange,
        });
      }

      // Session-based notifications require a signed-in user.
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final weekStart = now.subtract(const Duration(days: 7));
        final sessions = await SessionService.instance
            .getSessionHistory(startDate: weekStart, limit: 200);
        final completed =
            sessions.where((s) => s['status'] == 'completed').toList();

        final today = DateTime(now.year, now.month, now.day);
        final todaySessions = completed.where((s) {
          final start = DateTime.tryParse(s['start_time'] as String? ?? '');
          return start != null && !start.isBefore(today);
        }).length;

        final prefs = await SharedPreferences.getInstance();
        final dailyGoal = prefs.getInt('sessions_per_day') ?? 2;

        if (todaySessions >= dailyGoal && dailyGoal > 0) {
          notifications.add({
            'id': 'goal_done_$dayKey',
            'type': 'goal_achievement',
            'title': 'Daily Goal Achieved! 🎉',
            'description':
                'You completed $todaySessions session${todaySessions == 1 ? '' : 's'} today',
            'timestamp': now,
            'isRead': false,
            'icon': 'emoji_events',
            'iconColor': Colors.amber,
          });
        } else if (todaySessions > 0) {
          notifications.add({
            'id': 'goal_progress_$dayKey',
            'type': 'goal_progress',
            'title': 'Goal Progress',
            'description':
                '$todaySessions of $dailyGoal sessions logged today — keep it up!',
            'timestamp': now,
            'isRead': false,
            'icon': 'track_changes',
            'iconColor': Colors.green,
          });
        } else if (now.hour >= 12) {
          notifications.add({
            'id': 'no_session_$dayKey',
            'type': 'missed_session',
            'title': 'No Session Logged Today',
            'description':
                'There may still be time for a short session — check today\'s UV conditions first.',
            'timestamp': now,
            'isRead': false,
            'icon': 'schedule',
            'iconColor': Colors.blue,
          });
        }

        if (completed.isNotEmpty) {
          final weeklyMinutes = completed.fold<int>(
              0, (sum, s) => sum + ((s['duration_minutes'] as int?) ?? 0));
          notifications.add({
            'id': 'weekly_summary_$dayKey',
            'type': 'weekly_summary',
            'title': 'Your Week in the Sun',
            'description':
                '${completed.length} session${completed.length == 1 ? '' : 's'} and $weeklyMinutes minutes logged in the last 7 days',
            'timestamp': now.subtract(const Duration(hours: 1)),
            'isRead': false,
            'icon': 'insights',
            'iconColor': Colors.teal,
          });
        }
      }

      // Apply persisted read/dismissed state.
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList('read_notification_ids') ?? [];
      final dismissedIds =
          prefs.getStringList('dismissed_notification_ids') ?? [];
      notifications
          .removeWhere((n) => dismissedIds.contains(n['id'] as String));
      for (final n in notifications) {
        if (readIds.contains(n['id'] as String)) n['isRead'] = true;
      }
    } catch (e) {
      debugPrint('Error building notifications: $e');
    }

    if (!mounted) return;
    setState(() {
      _notifications = notifications;
      _unreadCount = notifications.where((n) => !(n['isRead'] as bool)).length;
      _isLoading = false;
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupNotificationsByDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final thisWeek = today.subtract(Duration(days: 7));

    final grouped = <String, List<Map<String, dynamic>>>{
      'Today': [],
      'Yesterday': [],
      'This Week': [],
    };

    for (final notification in _notifications) {
      final timestamp = notification['timestamp'] as DateTime;
      final notificationDate =
          DateTime(timestamp.year, timestamp.month, timestamp.day);

      if (notificationDate.isAtSameMomentAs(today)) {
        grouped['Today']!.add(notification);
      } else if (notificationDate.isAtSameMomentAs(yesterday)) {
        grouped['Yesterday']!.add(notification);
      } else if (notificationDate.isAfter(thisWeek)) {
        grouped['This Week']!.add(notification);
      }
    }

    // Remove empty groups
    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      for (final notification in _notifications) {
        notification['isRead'] = true;
      }
      _unreadCount = 0;
    });

    final prefs = await SharedPreferences.getInstance();
    final readIds =
        (prefs.getStringList('read_notification_ids') ?? []).toSet();
    readIds.addAll(_notifications.map((n) => n['id'] as String));
    await prefs.setStringList('read_notification_ids', readIds.toList());
  }

  Future<void> _markAsRead(String notificationId) async {
    setState(() {
      final notification =
          _notifications.firstWhere((n) => n['id'] == notificationId);
      if (!notification['isRead']) {
        notification['isRead'] = true;
        _unreadCount--;
      }
    });

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    final currentReadIds = prefs.getStringList('read_notification_ids') ?? [];
    if (!currentReadIds.contains(notificationId)) {
      currentReadIds.add(notificationId);
      await prefs.setStringList('read_notification_ids', currentReadIds);
    }
  }

  Future<void> _dismissNotification(String notificationId) async {
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        final wasUnread = !_notifications[index]['isRead'];
        _notifications.removeAt(index);
        if (wasUnread) _unreadCount--;
      }
    });

    // Save dismissed notifications
    final prefs = await SharedPreferences.getInstance();
    final dismissedIds =
        prefs.getStringList('dismissed_notification_ids') ?? [];
    if (!dismissedIds.contains(notificationId)) {
      dismissedIds.add(notificationId);
      await prefs.setStringList('dismissed_notification_ids', dismissedIds);
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _isLoading = true;
    });
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Notifications',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_unreadCount > 0) ...[
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _unreadCount.toString(),
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'close',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 6.w,
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark All Read',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.lightTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          IconButton(
            onPressed: () {
              // Navigate to notification settings in profile
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile-screen');
            },
            icon: CustomIconWidget(
              iconName: 'settings',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 5.w,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.lightTheme.primaryColor,
                ),
              ),
            )
          : _notifications.isEmpty
              ? EmptyNotificationsWidget()
              : RefreshIndicator(
                  onRefresh: _refreshNotifications,
                  color: AppTheme.lightTheme.primaryColor,
                  child: _buildNotificationsList(),
                ),
    );
  }

  Widget _buildNotificationsList() {
    final groupedNotifications = _groupNotificationsByDate();

    return ListView.builder(
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      itemCount: groupedNotifications.entries.length,
      itemBuilder: (context, index) {
        final entry = groupedNotifications.entries.elementAt(index);
        final groupTitle = entry.key;
        final notifications = entry.value;

        return NotificationGroupWidget(
          title: groupTitle,
          notifications: notifications,
          onNotificationTap: _markAsRead,
          onNotificationDismiss: _dismissNotification,
        );
      },
    );
  }
}