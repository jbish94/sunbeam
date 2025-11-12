import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class WeeklySummaryCardWidget extends StatelessWidget {
  final int totalSessions;
  final int totalDuration;
  final double averageMood;
  final double averageEnergy;
  final double weeklyGoalProgress;
  final AnimationController animationController;
  final String timePeriod;

  const WeeklySummaryCardWidget({
    Key? key,
    required this.totalSessions,
    required this.totalDuration,
    required this.averageMood,
    required this.averageEnergy,
    required this.weeklyGoalProgress,
    required this.animationController,
    required this.timePeriod,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(
          parent: animationController,
          curve: Interval(0.4, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: FadeTransition(
        opacity: animationController,
        child: Container(
          padding: EdgeInsets.all(5.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
                AppTheme.lightTheme.primaryColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getSummaryTitle(),
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getProgressColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(weeklyGoalProgress * 100).toInt()}% Goal',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: _getProgressColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryMetric(
                      'Sessions',
                      '$totalSessions',
                      Icons.wb_sunny_outlined,
                      Colors.orange,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 6.h,
                    color: AppTheme.lightTheme.dividerColor,
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                  ),
                  Expanded(
                    child: _buildSummaryMetric(
                      'Total Time',
                      '${totalDuration}m',
                      Icons.schedule_outlined,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              Container(
                width: double.infinity,
                height: 1,
                color: AppTheme.lightTheme.dividerColor,
              ),
              SizedBox(height: 3.h),
              Row(
                children: [
                  Expanded(
                    child: _buildMoodEnergyMetric(
                      'Avg Mood',
                      averageMood,
                      Icons.mood_outlined,
                      Colors.green,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: _buildMoodEnergyMetric(
                      'Avg Energy',
                      averageEnergy,
                      Icons.battery_charging_full_outlined,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              _buildGoalProgress(),
            ],
          ),
        ),
      ),
    );
  }

  String _getSummaryTitle() {
    switch (timePeriod) {
      case 'week':
        return 'This Week\'s Summary';
      case 'month':
        return 'This Month\'s Summary';
      case '3 months':
        return 'Last 3 Months Summary';
      default:
        return 'This Week\'s Summary';
    }
  }

  String _getGoalProgressTitle() {
    switch (timePeriod) {
      case 'week':
        return 'Weekly Goal Progress';
      case 'month':
        return 'Monthly Goal Progress';
      case '3 months':
        return 'Quarterly Goal Progress';
      default:
        return 'Weekly Goal Progress';
    }
  }

  Widget _buildSummaryMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 7.w),
        ),
        SizedBox(height: 1.5.h),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMoodEnergyMetric(
    String label,
    double value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 5.w),
              SizedBox(width: 2.w),
              Text(
                label,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Text(
                value > 0 ? value.toStringAsFixed(1) : 'N/A',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              if (value > 0) ...[
                SizedBox(width: 1.w),
                Text(
                  '/5.0',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 1.h),
          _buildRatingStars(value),
        ],
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star
              : (index < rating ? Icons.star_half : Icons.star_border),
          color: Colors.amber,
          size: 4.w,
        );
      }),
    );
  }

  Widget _buildGoalProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _getGoalProgressTitle(),
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(weeklyGoalProgress * 100).toInt()}%',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: _getProgressColor(),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: weeklyGoalProgress),
          duration: Duration(milliseconds: 1500),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return LinearProgressIndicator(
              value: value,
              backgroundColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
              minHeight: 1.h,
            );
          },
        ),
      ],
    );
  }

  Color _getProgressColor() {
    if (weeklyGoalProgress >= 1.0) return Colors.green;
    if (weeklyGoalProgress >= 0.7) return Colors.orange;
    return Colors.red;
  }
}
