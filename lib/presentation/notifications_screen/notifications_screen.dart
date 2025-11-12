import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
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

  Future<void> _loadNotifications() async {
    await Future.delayed(Duration(milliseconds: 500)); // Simulate loading

    // Mock notifications data - in real app this would come from API/database
    final notifications = [
      {
        'id': '1',
        'type': 'sun_window',
        'title': 'Optimal Sun Window Starting',
        'description': 'Perfect time for 15-minute vitamin D session',
        'timestamp': DateTime.now().subtract(Duration(minutes: 5)),
        'isRead': false,
        'icon': 'wb_sunny',
        'iconColor': Colors.orange,
      },
      {
        'id': '2',
        'type': 'goal_achievement',
        'title': 'Daily Goal Achieved! 🎉',
        'description': 'You completed 2 sun sessions today',
        'timestamp': DateTime.now().subtract(Duration(hours: 2)),
        'isRead': false,
        'icon': 'emoji_events',
        'iconColor': Colors.amber,
      },
      {
        'id': '3',
        'type': 'missed_session',
        'title': 'Missed Your Morning Session',
        'description': 'Don\'t worry, there\'s still time for afternoon sun',
        'timestamp': DateTime.now().subtract(Duration(hours: 4)),
        'isRead': true,
        'icon': 'schedule',
        'iconColor': Colors.blue,
      },
      {
        'id': '4',
        'type': 'education',
        'title': 'New Article: UV Safety Tips',
        'description': 'Learn about protecting your skin during high UV days',
        'timestamp': DateTime.now().subtract(Duration(days: 1)),
        'isRead': true,
        'icon': 'school',
        'iconColor': Colors.green,
      },
      {
        'id': '5',
        'type': 'weather_alert',
        'title': 'High UV Alert',
        'description': 'UV index will be 9+ today. Use SPF 50+ sunscreen',
        'timestamp': DateTime.now().subtract(Duration(days: 1, hours: 2)),
        'isRead': true,
        'icon': 'warning_amber',
        'iconColor': Colors.red,
      },
    ];

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

    // In real app, sync with backend
    final prefs = await SharedPreferences.getInstance();
    final readIds = _notifications.map((n) => n['id'] as String).toList();
    await prefs.setStringList('read_notification_ids', readIds);
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
    // Add haptic feedback
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      // iOS haptic feedback would be implemented here
    }
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