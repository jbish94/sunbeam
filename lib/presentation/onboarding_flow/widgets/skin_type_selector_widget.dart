import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SkinTypeSelectorWidget extends StatefulWidget {
  final Function(String?) onSkinTypeChanged;
  final String? selectedSkinType;

  const SkinTypeSelectorWidget({
    Key? key,
    required this.onSkinTypeChanged,
    this.selectedSkinType,
  }) : super(key: key);

  @override
  State<SkinTypeSelectorWidget> createState() => _SkinTypeSelectorWidgetState();
}

class _SkinTypeSelectorWidgetState extends State<SkinTypeSelectorWidget> {
  final List<Map<String, dynamic>> _skinTypes = [
    {
      'type': 'I',
      'description': 'Very Fair',
      'details': 'Always burns, never tans',
      'color': Color(0xFFFDF2E9),
      'semanticLabel': 'Very fair skin tone - pale peachy white color',
    },
    {
      'type': 'II',
      'description': 'Fair',
      'details': 'Usually burns, tans minimally',
      'color': Color(0xFFF1C27D),
      'semanticLabel': 'Fair skin tone - light beige color',
    },
    {
      'type': 'III',
      'description': 'Medium',
      'details': 'Sometimes burns, tans gradually',
      'color': Color(0xFFE0AC69),
      'semanticLabel': 'Medium skin tone - warm tan color',
    },
    {
      'type': 'IV',
      'description': 'Olive',
      'details': 'Burns minimally, tans well',
      'color': Color(0xFFC68642),
      'semanticLabel': 'Olive skin tone - golden brown color',
    },
    {
      'type': 'V',
      'description': 'Brown',
      'details': 'Rarely burns, tans darkly',
      'color': Color(0xFF8D5524),
      'semanticLabel': 'Brown skin tone - rich caramel brown color',
    },
    {
      'type': 'VI',
      'description': 'Dark Brown',
      'details': 'Never burns, always tans darkly',
      'color': Color(0xFF654321),
      'semanticLabel': 'Dark brown skin tone - deep chocolate brown color',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s your skin type?',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Select your Fitzpatrick skin type to get personalized sun exposure recommendations',
          style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 4.h),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 3.w,
            mainAxisSpacing: 2.h,
          ),
          itemCount: _skinTypes.length,
          itemBuilder: (context, index) {
            return _buildSkinTypeCard(_skinTypes[index]);
          },
        ),
      ],
    );
  }

  Widget _buildSkinTypeCard(Map<String, dynamic> skinType) {
    final bool isSelected = widget.selectedSkinType == skinType['type'];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onSkinTypeChanged(skinType['type']),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1)
                : AppTheme.lightTheme.colorScheme.surface,
            border: Border.all(
              color: isSelected
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Color representation section (smaller height)
              Container(
                height: 8.h,
                width: double.infinity,
                margin: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: skinType['color'],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        skinType['color'],
                        Color.lerp(skinType['color'], Colors.black, 0.1)!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
              // Text content section with better spacing
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(3.w, 0, 3.w, 2.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 2.w, vertical: 0.8.w),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme
                                            .lightTheme.colorScheme.primary
                                        : AppTheme
                                            .lightTheme.colorScheme.primary
                                            .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Type ${skinType['type']}',
                                    style: AppTheme
                                        .lightTheme.textTheme.labelSmall
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10.sp,
                                      color: isSelected
                                          ? AppTheme
                                              .lightTheme.colorScheme.onPrimary
                                          : AppTheme
                                              .lightTheme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              if (isSelected)
                                CustomIconWidget(
                                  iconName: 'check_circle',
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  size: 3.5.w,
                                ),
                            ],
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            skinType['description'],
                            style: AppTheme.lightTheme.textTheme.titleSmall
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.sp,
                              color: AppTheme.lightTheme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      // Details text at bottom with proper spacing
                      Padding(
                        padding: EdgeInsets.only(bottom: 0.5.h),
                        child: Text(
                          skinType['details'],
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            fontSize: 10.sp,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
