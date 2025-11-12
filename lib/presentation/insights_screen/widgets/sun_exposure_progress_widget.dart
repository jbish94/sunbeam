import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SunExposureProgressWidget extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData;
  final int recommendedMinutes;
  final AnimationController animationController;

  const SunExposureProgressWidget({
    Key? key,
    required this.weeklyData,
    required this.recommendedMinutes,
    required this.animationController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalMinutes = _getTotalMinutes();
    final progress = totalMinutes / recommendedMinutes;
    final dailyAverage = totalMinutes / 7;
    final recommendedDaily = recommendedMinutes / 7;

    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: Interval(0.7, 1.0, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: animationController,
        child: Container(
          padding: EdgeInsets.all(5.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'wb_sunny',
                      color: Colors.amber,
                      size: 5.w,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sun Exposure Progress',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Weekly vitamin D synthesis goal',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              _buildProgressCircle(progress, totalMinutes),
              SizedBox(height: 4.h),
              _buildProgressStats(totalMinutes, dailyAverage, recommendedDaily),
              SizedBox(height: 3.h),
              _buildWeeklyBreakdown(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCircle(double progress, int totalMinutes) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 35.w,
            height: 35.w,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress.clamp(0.0, 1.0)),
              duration: Duration(milliseconds: 2000),
              curve: Curves.easeOut,
              builder: (context, animatedProgress, child) {
                return CircularProgressIndicator(
                  value: animatedProgress,
                  strokeWidth: 2.5.w,
                  backgroundColor: AppTheme
                      .lightTheme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(progress)),
                );
              },
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$totalMinutes',
                style: AppTheme.lightTheme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _getProgressColor(progress),
                ),
              ),
              Text(
                'minutes',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                '${(progress * 100).toInt()}% of goal',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: _getProgressColor(progress),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStats(
      int totalMinutes, double dailyAverage, double recommendedDaily) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatColumn(
                  'Total This Week',
                  '$totalMinutes min',
                  'vs $recommendedMinutes min goal',
                  Colors.blue,
                ),
              ),
              Container(
                width: 1,
                height: 6.h,
                color: AppTheme.lightTheme.dividerColor,
                margin: EdgeInsets.symmetric(horizontal: 4.w),
              ),
              Expanded(
                child: _buildStatColumn(
                  'Daily Average',
                  '${dailyAverage.toStringAsFixed(1)} min',
                  'vs ${recommendedDaily.toStringAsFixed(1)} min rec.',
                  Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          _buildProgressInsight(totalMinutes),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
      String title, String value, String subtitle, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 1.h),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 0.5.h),
        Text(
          subtitle,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressInsight(int totalMinutes) {
    String insight;
    IconData icon;
    Color color;

    final progress = totalMinutes / recommendedMinutes;

    if (progress >= 1.0) {
      insight =
          "Excellent! You've met your weekly vitamin D synthesis goal. 🌟";
      icon = Icons.emoji_events;
      color = Colors.green;
    } else if (progress >= 0.7) {
      insight =
          "You're on track! Just a bit more sun exposure to reach your goal.";
      icon = Icons.trending_up;
      color = Colors.orange;
    } else if (progress >= 0.4) {
      insight = "Good start! Try to increase your daily sun exposure sessions.";
      icon = Icons.info;
      color = Colors.blue;
    } else {
      insight =
          "You need more consistent sun exposure to meet your vitamin D needs.";
      icon = Icons.warning_amber;
      color = Colors.red;
    }

    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 4.w,
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            insight,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Breakdown',
          style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2.h),
        ...weeklyData.map((dayData) => _buildDayRow(dayData)).toList(),
      ],
    );
  }

  Widget _buildDayRow(Map<String, dynamic> dayData) {
    final duration = dayData['duration'] as int;
    final sessions = dayData['sessions'] as int;
    final day = dayData['day'] as String;
    final uvExposure = dayData['uvExposure'] as int;

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: duration > 0
            ? AppTheme.lightTheme.primaryColor.withValues(alpha: 0.03)
            : AppTheme.lightTheme.colorScheme.onSurfaceVariant
                .withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: duration > 0
              ? AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1)
              : AppTheme.lightTheme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            child: Text(
              day,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Row(
              children: [
                if (duration > 0) ...[
                  Icon(
                    Icons.wb_sunny,
                    color: Colors.orange,
                    size: 4.w,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '${duration}m',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    '$sessions session${sessions != 1 ? 's' : ''}',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.remove_circle_outline,
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.5),
                    size: 4.w,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'No sessions',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (duration > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: _getUVColor(uvExposure).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${uvExposure} UV',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: _getUVColor(uvExposure),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return Colors.orange;
    if (progress >= 0.4) return Colors.blue;
    return Colors.red;
  }

  Color _getUVColor(int uvExposure) {
    if (uvExposure >= 80) return Colors.green;
    if (uvExposure >= 50) return Colors.orange;
    if (uvExposure >= 20) return Colors.blue;
    return Colors.red;
  }

  int _getTotalMinutes() {
    return weeklyData.fold(0, (sum, day) => sum + (day['duration'] as int));
  }
}
