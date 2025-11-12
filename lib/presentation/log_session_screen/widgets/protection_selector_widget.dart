import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProtectionSelectorWidget extends StatelessWidget {
  final List<String> selectedProtections;
  final Function(List<String>) onProtectionChanged;

  const ProtectionSelectorWidget({
    Key? key,
    required this.selectedProtections,
    required this.onProtectionChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final protectionOptions = [
      {'label': 'None', 'icon': 'wb_sunny'},
      {'label': 'SPF 15', 'icon': 'local_pharmacy'},
      {'label': 'SPF 30', 'icon': 'local_pharmacy'},
      {'label': 'SPF 50+', 'icon': 'local_pharmacy'},
      {'label': 'Clothing', 'icon': 'checkroom'},
      {'label': 'Shade', 'icon': 'umbrella'},
    ];

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
            'Protection Used',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Select all that apply',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 2.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.5.h,
            children: protectionOptions.map((option) {
              final label = option['label'] as String;
              final icon = option['icon'] as String;
              final isSelected = selectedProtections.contains(label);

              return InkWell(
                onTap: () => _toggleProtection(label),
                borderRadius: BorderRadius.circular(2.w),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.1)
                        : AppTheme.lightTheme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(2.w),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.outline
                              .withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: icon,
                        color: isSelected
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        label,
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.lightTheme.colorScheme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      if (isSelected) ...[
                        SizedBox(width: 1.w),
                        CustomIconWidget(
                          iconName: 'check_circle',
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 4.w,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _toggleProtection(String protection) {
    List<String> newProtections = List.from(selectedProtections);

    if (protection == 'None') {
      // If None is selected, clear all other selections
      newProtections = ['None'];
    } else {
      // Remove 'None' if any other protection is selected
      newProtections.remove('None');

      if (newProtections.contains(protection)) {
        newProtections.remove(protection);
      } else {
        newProtections.add(protection);
      }

      // If no protections selected, default to 'None'
      if (newProtections.isEmpty) {
        newProtections = ['None'];
      }
    }

    onProtectionChanged(newProtections);
  }
}
