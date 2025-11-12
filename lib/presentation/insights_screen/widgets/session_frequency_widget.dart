import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SessionFrequencyWidget extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData;
  final AnimationController animationController;

  const SessionFrequencyWidget({
    Key? key,
    required this.weeklyData,
    required this.animationController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(-0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: Interval(0.6, 1.0, curve: Curves.easeOut),
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
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'bar_chart',
                      color: Colors.blue,
                      size: 5.w,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session Frequency',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Daily sun exposure sessions',
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
              SizedBox(height: 3.h),
              Container(
                height: 25.h,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 1800),
                  curve: Curves.easeOut,
                  builder: (context, animationValue, child) {
                    return BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxSessions().toDouble() + 1,
                        minY: 0,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: AppTheme.lightTheme.dividerColor
                                  .withValues(alpha: 0.3),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                  ),
                                );
                              },
                              reservedSize: 8.w,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 &&
                                    value.toInt() < weeklyData.length) {
                                  return Text(
                                    weeklyData[value.toInt()]['day'],
                                    style: AppTheme
                                        .lightTheme.textTheme.bodySmall
                                        ?.copyWith(
                                      color: AppTheme.lightTheme.colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  );
                                }
                                return Text('');
                              },
                              reservedSize: 6.h,
                            ),
                          ),
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: _buildBarGroups(animationValue),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final dayData = weeklyData[group.x.toInt()];
                              return BarTooltipItem(
                                '${dayData['day']}\n${dayData['sessions']} session${dayData['sessions'] != 1 ? 's' : ''}\n${dayData['duration']} minutes',
                                TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10.sp,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 3.h),
              _buildFrequencyStats(),
            ],
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(double animationValue) {
    return weeklyData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final sessions = data['sessions'] as int;
      final duration = data['duration'] as int;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (sessions * animationValue),
            color: _getBarColor(sessions, duration),
            width: 8.w,
            borderRadius: BorderRadius.circular(1.w),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                _getBarColor(sessions, duration).withValues(alpha: 0.7),
                _getBarColor(sessions, duration),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  Color _getBarColor(int sessions, int duration) {
    if (sessions == 0) return Colors.grey.withValues(alpha: 0.3);
    if (sessions >= 2 || duration >= 30) return Colors.green;
    if (sessions == 1 && duration >= 15) return Colors.orange;
    return Colors.red.withValues(alpha: 0.7);
  }

  int _getMaxSessions() {
    return weeklyData
        .map((day) => day['sessions'] as int)
        .reduce((a, b) => a > b ? a : b);
  }

  Widget _buildFrequencyStats() {
    final totalSessions =
        weeklyData.fold(0, (sum, day) => sum + (day['sessions'] as int));
    final activeDays = weeklyData.where((day) => day['sessions'] > 0).length;
    final consistencyScore = (activeDays / 7.0 * 100).round();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Sessions',
                  '$totalSessions',
                  Icons.wb_sunny,
                  Colors.orange,
                ),
              ),
              Container(
                width: 1,
                height: 5.h,
                color: AppTheme.lightTheme.dividerColor,
              ),
              Expanded(
                child: _buildStatItem(
                  'Active Days',
                  '$activeDays/7',
                  Icons.calendar_today,
                  Colors.blue,
                ),
              ),
              Container(
                width: 1,
                height: 5.h,
                color: AppTheme.lightTheme.dividerColor,
              ),
              Expanded(
                child: _buildStatItem(
                  'Consistency',
                  '$consistencyScore%',
                  Icons.trending_up,
                  _getConsistencyColor(consistencyScore),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildConsistencyInsight(consistencyScore, activeDays),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 5.w,
        ),
        SizedBox(height: 1.h),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildConsistencyInsight(int consistencyScore, int activeDays) {
    String insight;
    IconData icon;
    Color color;

    if (consistencyScore >= 85) {
      insight =
          "Excellent consistency! You're building a strong sun exposure routine.";
      icon = Icons.emoji_events;
      color = Colors.green;
    } else if (consistencyScore >= 60) {
      insight = "Good consistency! Try to maintain regular daily sessions.";
      icon = Icons.thumb_up;
      color = Colors.orange;
    } else {
      insight =
          "Try to be more consistent with daily sun exposure sessions for better benefits.";
      icon = Icons.info;
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

  Color _getConsistencyColor(int score) {
    if (score >= 85) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
