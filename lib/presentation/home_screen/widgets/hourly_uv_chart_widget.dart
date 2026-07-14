import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class HourlyUvChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> hourlyData;

  const HourlyUvChartWidget({
    Key? key,
    required this.hourlyData,
  }) : super(key: key);

  @override
  State<HourlyUvChartWidget> createState() => _HourlyUvChartWidgetState();
}

class _HourlyUvChartWidgetState extends State<HourlyUvChartWidget> {
  int? touchedIndex;

  /// Limits the chart to daylight-relevant hours (6AM-9PM) so the
  /// overnight zero-UV tail doesn't waste width. Entries without a
  /// `dt` (placeholder data) are kept as-is.
  List<Map<String, dynamic>> get _displayData {
    final filtered = widget.hourlyData.where((h) {
      final dt = h['dt'];
      if (dt is DateTime) return dt.hour >= 6 && dt.hour <= 21;
      return true;
    }).toList();
    return filtered.isEmpty ? widget.hourlyData : filtered;
  }

  @override
  Widget build(BuildContext context) {
    final data = _displayData;
    // Aim for ~6 x-axis labels regardless of how many points we have.
    final labelInterval = (data.length / 6).ceil().clamp(1, 24);
    return Container(
      width: double.infinity,
      height: 30.h,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s UV Index',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              CustomIconWidget(
                iconName: 'wb_sunny',
                color: AppTheme.lightTheme.primaryColor,
                size: 20,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (data.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'cloud_off',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 32,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'UV forecast unavailable',
                      style: AppTheme.lightTheme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Pull down to refresh',
                      style:
                          AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color:
                            AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
          Expanded(
            child: Semantics(
              label:
                  "Hourly UV Index Chart showing today's UV levels throughout the day",
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppTheme.lightTheme.dividerColor,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: labelInterval.toDouble(),
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final hour = value.toInt();
                          // Skip the forced edge label fl_chart renders at
                          // maxX — it collides with its neighbour.
                          if (hour % labelInterval != 0) {
                            return const SizedBox.shrink();
                          }
                          if (hour >= 0 && hour < data.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                data[hour]['time'] as String,
                                style: AppTheme.lightTheme.textTheme.bodySmall
                                    ?.copyWith(
                                  fontSize: 10.sp,
                                ),
                              ),
                            );
                          }
                          return Container();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2,
                        reservedSize: 40,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              value.toInt().toString(),
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                fontSize: 10.sp,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: AppTheme.lightTheme.dividerColor,
                      width: 1,
                    ),
                  ),
                  minX: 0,
                  maxX: (data.length - 1).toDouble(),
                  minY: 0,
                  maxY: 12,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchCallback:
                        (FlTouchEvent event, LineTouchResponse? touchResponse) {
                      setState(() {
                        if (touchResponse != null &&
                            touchResponse.lineBarSpots != null) {
                          touchedIndex =
                              touchResponse.lineBarSpots!.first.spotIndex;
                        } else {
                          touchedIndex = null;
                        }
                      });
                    },
                    getTouchedSpotIndicator:
                        (LineChartBarData barData, List<int> spotIndexes) {
                      return spotIndexes.map((spotIndex) {
                        return TouchedSpotIndicatorData(
                          FlLine(
                            color: AppTheme.lightTheme.primaryColor,
                            strokeWidth: 2,
                          ),
                          FlDotData(
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 6,
                                color: AppTheme.lightTheme.primaryColor,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                        );
                      }).toList();
                    },
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: AppTheme.lightTheme.primaryColor,
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          final flSpot = barSpot;
                          final index = flSpot.x.toInt();
                          if (index >= 0 && index < data.length) {
                            final point = data[index];
                            return LineTooltipItem(
                              '${point['time']}\nUV: ${flSpot.y.toInt()}\n${point['temp']}°F',
                              TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.sp,
                              ),
                            );
                          }
                          return null;
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          (entry.value['uvIndex'] as num).toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.lightTheme.primaryColor,
                          AppTheme.lightTheme.primaryColor
                              .withValues(alpha: 0.7),
                        ],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: AppTheme.lightTheme.primaryColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.lightTheme.primaryColor
                                .withValues(alpha: 0.3),
                            AppTheme.lightTheme.primaryColor
                                .withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}