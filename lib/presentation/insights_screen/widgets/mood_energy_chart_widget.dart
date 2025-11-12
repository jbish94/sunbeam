import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MoodEnergyChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData;
  final AnimationController animationController;

  const MoodEnergyChartWidget({
    Key? key,
    required this.weeklyData,
    required this.animationController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animationController,
        curve: Interval(0.5, 1.0, curve: Curves.easeOut),
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
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomIconWidget(
                      iconName: 'trending_up',
                      color: Colors.purple,
                      size: 5.w,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mood & Energy Trends',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Track your wellbeing patterns',
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
              _buildChartLegend(),
              SizedBox(height: 2.h),
              Container(
                height: 30.h,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 1500),
                  curve: Curves.easeOut,
                  builder: (context, animationValue, child) {
                    return LineChart(
                      LineChartData(
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
                        minX: 0,
                        maxX: (weeklyData.length - 1).toDouble(),
                        minY: 0,
                        maxY: 5,
                        lineBarsData: [
                          _buildMoodLine(animationValue),
                          _buildEnergyLine(animationValue),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final dayData = weeklyData[spot.x.toInt()];
                                final isFirstLine = spot.barIndex == 0;
                                return LineTooltipItem(
                                  '${dayData['day']}\n${isFirstLine ? 'Mood' : 'Energy'}: ${spot.y.toStringAsFixed(1)}',
                                  TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10.sp,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 2.h),
              _buildInsightSummary(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartLegend() {
    return Row(
      children: [
        _buildLegendItem('Mood', Colors.green, Icons.mood),
        SizedBox(width: 4.w),
        _buildLegendItem('Energy', Colors.orange, Icons.battery_charging_full),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 4.w,
        ),
        SizedBox(width: 1.w),
        Container(
          width: 3.w,
          height: 0.3.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 1.w),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  LineChartBarData _buildMoodLine(double animationValue) {
    return LineChartBarData(
      spots: _getMoodSpots(animationValue),
      isCurved: true,
      color: Colors.green,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 4,
          color: Colors.green,
          strokeWidth: 2,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: Colors.green.withValues(alpha: 0.1),
      ),
    );
  }

  LineChartBarData _buildEnergyLine(double animationValue) {
    return LineChartBarData(
      spots: _getEnergySpots(animationValue),
      isCurved: true,
      color: Colors.orange,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 4,
          color: Colors.orange,
          strokeWidth: 2,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: Colors.orange.withValues(alpha: 0.1),
      ),
    );
  }

  List<FlSpot> _getMoodSpots(double animationValue) {
    List<FlSpot> spots = [];
    for (int i = 0; i < weeklyData.length; i++) {
      final mood = weeklyData[i]['mood'] as double;
      if (mood > 0) {
        spots.add(FlSpot(i.toDouble(), mood * animationValue));
      }
    }
    return spots;
  }

  List<FlSpot> _getEnergySpots(double animationValue) {
    List<FlSpot> spots = [];
    for (int i = 0; i < weeklyData.length; i++) {
      final energy = weeklyData[i]['energy'] as double;
      if (energy > 0) {
        spots.add(FlSpot(i.toDouble(), energy * animationValue));
      }
    }
    return spots;
  }

  Widget _buildInsightSummary() {
    final avgMood = _calculateAverage('mood');
    final avgEnergy = _calculateAverage('energy');
    final trend = _analyzeTrend();

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'lightbulb',
                color: AppTheme.lightTheme.primaryColor,
                size: 4.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Quick Insights',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Your average mood this week is ${avgMood.toStringAsFixed(1)}/5 and energy level is ${avgEnergy.toStringAsFixed(1)}/5. $trend',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateAverage(String key) {
    final validValues = weeklyData
        .where((day) => day[key] > 0)
        .map((day) => day[key] as double);
    if (validValues.isEmpty) return 0.0;
    return validValues.reduce((a, b) => a + b) / validValues.length;
  }

  String _analyzeTrend() {
    final validMoods = weeklyData
        .where((day) => day['mood'] > 0)
        .map((day) => day['mood'] as double)
        .toList();
    if (validMoods.length < 2) return 'Keep logging sessions to see trends!';

    final firstHalf = validMoods.sublist(0, (validMoods.length / 2).ceil());
    final secondHalf = validMoods.sublist((validMoods.length / 2).ceil());

    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

    if (secondAvg > firstAvg + 0.2) {
      return 'Your mood is trending upward - great progress! ✨';
    } else if (firstAvg > secondAvg + 0.2) {
      return 'Consider adjusting your sun exposure routine for better mood benefits.';
    } else {
      return 'Your mood levels are stable throughout the week.';
    }
  }
}
