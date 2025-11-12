import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SessionSummaryWidget extends StatelessWidget {
  final DateTime startTime;
  final int duration;
  final List<String> protections;
  final double moodLevel;
  final double energyLevel;
  final String notes;
  final bool isRecommendedWindow;

  const SessionSummaryWidget({
    Key? key,
    required this.startTime,
    required this.duration,
    required this.protections,
    required this.moodLevel,
    required this.energyLevel,
    required this.notes,
    required this.isRecommendedWindow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'summarize',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Session Summary',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          _buildSummaryRow(
            'Time',
            _formatTime(startTime),
            'access_time',
          ),
          SizedBox(height: 2.h),
          _buildSummaryRow(
            'Duration',
            '$duration minutes',
            'timer',
          ),
          SizedBox(height: 2.h),
          _buildSummaryRow(
            'Protection',
            protections.join(', '),
            'shield',
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMoodEnergyCard(
                  'Mood',
                  _getMoodEmoji(moodLevel),
                  _getMoodLabel(moodLevel),
                  AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMoodEnergyCard(
                  'Energy',
                  _getEnergyEmoji(energyLevel),
                  _getEnergyLabel(energyLevel),
                  AppTheme.lightTheme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            SizedBox(height: 2.h),
            _buildNotesSection(),
          ],
          if (isRecommendedWindow) ...[
            SizedBox(height: 2.h),
            _buildOptimalWindowBadge(),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, String iconName) {
    return Row(
      children: [
        CustomIconWidget(
          iconName: iconName,
          color:
              AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
          size: 5.w,
        ),
        SizedBox(width: 3.w),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface
                .withValues(alpha: 0.7),
          ),
        ),
        Spacer(),
        Flexible(
          child: Text(
            value,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMoodEnergyCard(
      String label, String emoji, String description, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: 20.sp),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
          Text(
            description,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'note',
                color: AppTheme.lightTheme.colorScheme.onSurface
                    .withValues(alpha: 0.7),
                size: 4.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Notes',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface
                      .withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            notes,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOptimalWindowBadge() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.getSuccessColor(true).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(
          color: AppTheme.getSuccessColor(true).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'verified',
            color: AppTheme.getSuccessColor(true),
            size: 5.w,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Optimal Sun Window',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.getSuccessColor(true),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Great timing! This session was during your recommended window.',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color:
                        AppTheme.getSuccessColor(true).withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour =
        time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _getMoodEmoji(double level) {
    final moodEmojis = ['😢', '😕', '😐', '😊', '😄'];
    return moodEmojis[level.round() - 1];
  }

  String _getMoodLabel(double level) {
    final moodLabels = ['Poor', 'Low', 'Okay', 'Good', 'Great'];
    return moodLabels[level.round() - 1];
  }

  String _getEnergyEmoji(double level) {
    final energyEmojis = ['🔋', '🪫', '⚡', '💪', '🚀'];
    return energyEmojis[level.round() - 1];
  }

  String _getEnergyLabel(double level) {
    final energyLabels = ['Drained', 'Low', 'Okay', 'High', 'Energized'];
    return energyLabels[level.round() - 1];
  }
}
