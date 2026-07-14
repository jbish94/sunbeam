import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Prominent "Current UV" tile at the top of the home screen for
/// at-a-glance reference. Colors follow the WHO UV index scale.
class CurrentUvCardWidget extends StatelessWidget {
  /// Current UV index; null shows the unavailable/loading state.
  final double? uvIndex;
  final bool isLoading;

  const CurrentUvCardWidget({
    Key? key,
    this.uvIndex,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uv = uvIndex;
    final color = uv != null
        ? _uvColor(uv)
        : AppTheme.lightTheme.colorScheme.onSurfaceVariant;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 14.w,
            height: 14.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isLoading && uv == null
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    uv != null ? _formatUv(uv) : '--',
                    style: AppTheme.lightTheme.textTheme.headlineSmall
                        ?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current UV Index',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  uv != null
                      ? _levelLabel(uv)
                      : (isLoading ? 'Loading…' : 'Unavailable'),
                  style:
                      AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: uv != null
                        ? color
                        : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  _guidance(uv),
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Whole numbers render without a trailing ".0" (11, not 11.0).
  String _formatUv(double uv) {
    return uv == uv.roundToDouble()
        ? uv.round().toString()
        : uv.toStringAsFixed(1);
  }

  // WHO UV index scale colors. Moderate uses a dark amber so the white
  // number stays readable on the badge.
  Color _uvColor(double uv) {
    if (uv <= 2) return const Color(0xFF4CAF50); // Low — green
    if (uv <= 5) return const Color(0xFFF57F17); // Moderate — amber
    if (uv <= 7) return const Color(0xFFEF6C00); // High — orange
    if (uv <= 10) return const Color(0xFFD32F2F); // Very High — red
    return const Color(0xFF7B1FA2); // Extreme — violet
  }

  String _levelLabel(double uv) {
    if (uv <= 2) return 'Low';
    if (uv <= 5) return 'Moderate';
    if (uv <= 7) return 'High';
    if (uv <= 10) return 'Very High';
    return 'Extreme';
  }

  String _guidance(double? uv) {
    if (uv == null) {
      return isLoading
          ? 'Fetching current conditions…'
          : 'Pull down to refresh';
    }
    if (uv <= 2) return 'Minimal protection needed';
    if (uv <= 5) return 'Seek shade during midday';
    if (uv <= 7) return 'Hat and sunscreen recommended';
    if (uv <= 10) return 'Extra protection — limit midday sun';
    return 'Avoid direct sun during midday hours';
  }
}
