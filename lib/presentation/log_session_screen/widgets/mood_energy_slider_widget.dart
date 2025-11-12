import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MoodEnergySliderWidget extends StatelessWidget {
  final double moodLevel;
  final double energyLevel;
  final Function(double) onMoodChanged;
  final Function(double) onEnergyChanged;

  const MoodEnergySliderWidget({
    Key? key,
    required this.moodLevel,
    required this.energyLevel,
    required this.onMoodChanged,
    required this.onEnergyChanged,
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
          Text(
            'How are you feeling?',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 3.h),
          _buildMoodSlider(context),
          SizedBox(height: 3.h),
          _buildEnergySlider(context),
        ],
      ),
    );
  }

  Widget _buildMoodSlider(BuildContext context) {
    final moodEmojis = ['😢', '😕', '😐', '😊', '😄'];
    final moodLabels = ['Poor', 'Low', 'Okay', 'Good', 'Great'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomIconWidget(
              iconName: 'mood',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 5.w,
            ),
            SizedBox(width: 2.w),
            Text(
              'Mood',
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2.w),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    moodEmojis[moodLevel.round() - 1],
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    moodLabels[moodLevel.round() - 1],
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.lightTheme.colorScheme.primary,
            inactiveTrackColor:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
            thumbColor: AppTheme.lightTheme.colorScheme.primary,
            overlayColor:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
            trackHeight: 1.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 3.w),
          ),
          child: Slider(
            value: moodLevel,
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              onMoodChanged(value);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            return Column(
              children: [
                Text(
                  moodEmojis[index],
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: moodLevel.round() == index + 1
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '${index + 1}',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: moodLevel.round() == index + 1
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEnergySlider(BuildContext context) {
    final energyEmojis = ['🔋', '🪫', '⚡', '💪', '🚀'];
    final energyLabels = ['Drained', 'Low', 'Okay', 'High', 'Energized'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomIconWidget(
              iconName: 'battery_charging_full',
              color: AppTheme.lightTheme.colorScheme.secondary,
              size: 5.w,
            ),
            SizedBox(width: 2.w),
            Text(
              'Energy',
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.secondary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2.w),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    energyEmojis[energyLevel.round() - 1],
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    energyLabels[energyLevel.round() - 1],
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.lightTheme.colorScheme.secondary,
            inactiveTrackColor: AppTheme.lightTheme.colorScheme.secondary
                .withValues(alpha: 0.3),
            thumbColor: AppTheme.lightTheme.colorScheme.secondary,
            overlayColor: AppTheme.lightTheme.colorScheme.secondary
                .withValues(alpha: 0.2),
            trackHeight: 1.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 3.w),
          ),
          child: Slider(
            value: energyLevel,
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (value) {
              HapticFeedback.selectionClick();
              onEnergyChanged(value);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (index) {
            return Column(
              children: [
                Text(
                  energyEmojis[index],
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: energyLevel.round() == index + 1
                        ? AppTheme.lightTheme.colorScheme.secondary
                        : AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '${index + 1}',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: energyLevel.round() == index + 1
                        ? AppTheme.lightTheme.colorScheme.secondary
                        : AppTheme.lightTheme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}