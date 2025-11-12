import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class WeatherBadgesWidget extends StatelessWidget {
  final int temperature;
  final String cloudCover;
  final String windSpeed;
  final String humidity;

  const WeatherBadgesWidget({
    Key? key,
    required this.temperature,
    required this.cloudCover,
    required this.windSpeed,
    required this.humidity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          Expanded(
            child: _buildWeatherBadge(
              icon: 'thermostat',
              label: 'Temperature',
              value: '${temperature}°F',
              color: _getTemperatureColor(temperature),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildWeatherBadge(
              icon: 'cloud',
              label: 'Cloud Cover',
              value: cloudCover,
              color: AppTheme.lightTheme.colorScheme.secondary,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildWeatherBadge(
              icon: 'air',
              label: 'Wind',
              value: windSpeed,
              color: AppTheme.lightTheme.colorScheme.tertiary,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildWeatherBadge(
              icon: 'water_drop',
              label: 'Humidity',
              value: humidity,
              color: AppTheme.lightTheme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherBadge({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: icon,
            color: color,
            size: 20,
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getTemperatureColor(int temp) {
    if (temp >= 80) {
      return Colors.red;
    } else if (temp >= 65) {
      return AppTheme.lightTheme.primaryColor;
    } else if (temp >= 50) {
      return AppTheme.lightTheme.colorScheme.secondary;
    } else {
      return Colors.blue;
    }
  }
}
