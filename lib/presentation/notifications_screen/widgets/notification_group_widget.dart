import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import './notification_card_widget.dart';

class NotificationGroupWidget extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> notifications;
  final Function(String)? onNotificationTap;
  final Function(String)? onNotificationDismiss;

  const NotificationGroupWidget({
    Key? key,
    required this.title,
    required this.notifications,
    this.onNotificationTap,
    this.onNotificationDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header
        Padding(
          padding: EdgeInsets.only(left: 1.w, bottom: 2.h),
          child: Text(
            title,
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),

        // Notifications list
        ...notifications.map((notification) {
          return NotificationCardWidget(
            notification: notification,
            onTap: () => onNotificationTap?.call(notification['id']),
            onDismiss: () => onNotificationDismiss?.call(notification['id']),
          );
        }).toList(),

        // Spacing between groups
        SizedBox(height: 2.h),
      ],
    );
  }
}
