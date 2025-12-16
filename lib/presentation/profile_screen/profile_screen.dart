import 'dart:convert';
import 'dart:io' if (dart.library.io) 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:universal_html/html.dart' as html;

import '../../core/app_export.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import './age_range_edit_screen.dart';
import './bmi_selection_screen.dart';
import './burn_sensitivity_edit_screen.dart';
import './goal_edit_screen.dart';
import './location_settings_screen.dart';
import './name_edit_screen.dart';
import './skin_type_edit_screen.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_item_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/subscription_card_widget.dart';
import './widgets/toggle_item_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // SUBSCRIPTION FEATURE FLAG - Set to false to hide subscription features
  static const bool _showSubscriptionFeatures = false;

  // EXPORT DATA FEATURE FLAG - Set to false to hide export data feature
  static const bool _showExportDataFeature = false;

  int _selectedNavIndex = 3; // Set to profile tab

  // User data - will be loaded from SharedPreferences
  Map<String, dynamic> userData = {
    "name": "User",
    "email": "",
    "location": "San Francisco, CA",
    "accountStatus": "Pro",
    "skinType": "Type III - Light Brown",
    "burnSensitivity": 3,
    "ageRange": "25-34",
    "bmiRange": "18.5-24.9",
    "timezone": "PST (GMT-8)",
    "gpsAccuracy": "High",
    // SUBSCRIPTION DATA - Hidden but preserved for future use
    "subscriptionPlan": "Pro",
    "subscriptionPrice": "\$3.99/month",
    "subscriptionDescription":
        "Unlimited UV tracking, advanced insights, and premium features",
    "joinDate": "2024-01-15",
    "totalSessions": 127,
    "streakDays": 15,
  };

  // Settings state
  bool _optimalWindowAlerts = true;
  bool _missedSessionReminders = true;
  bool _educationalContent = false;
  bool _appleHealthSync = true;
  bool _googleFitSync = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load user name and email from welcome screen
      final savedName = prefs.getString('user_name');
      final savedEmail = prefs.getString('user_email');

      // Load location data
      final savedLocation = prefs.getString('user_location');
      final savedTimezone = prefs.getString('user_timezone');
      final savedGpsAccuracy = prefs.getString('gps_accuracy');
      final highPrecisionGps = prefs.getBool('high_precision_gps') ?? true;

      if (savedName != null || savedEmail != null || savedLocation != null) {
        setState(() {
          if (savedName != null && savedName.isNotEmpty) {
            userData["name"] = savedName;
          }
          if (savedEmail != null && savedEmail.isNotEmpty) {
            userData["email"] = savedEmail;
          }
          if (savedLocation != null && savedLocation.isNotEmpty) {
            userData["location"] = savedLocation;
          }
          if (savedTimezone != null && savedTimezone.isNotEmpty) {
            userData["timezone"] = savedTimezone;
          }
          if (savedGpsAccuracy != null && savedGpsAccuracy.isNotEmpty) {
            userData["gpsAccuracy"] = savedGpsAccuracy;
          }
        });
      }

      // Try to get current location from Supabase if no saved location
      if (savedLocation == null || savedLocation.isEmpty) {
        _loadLocationFromSupabase();
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadLocationFromSupabase() async {
    try {
      final locationService = LocationService.instance;
      final currentLocation =
          await locationService.getCurrentLocationFromSupabase();

      if (currentLocation != null && currentLocation['address'] != null) {
        setState(() {
          userData["location"] = currentLocation['address'];
        });
      }
    } catch (e) {
      print('Error loading location from Supabase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 2.h),

            // Profile Header - Pass subscription visibility flag
            ProfileHeaderWidget(
              userName: userData["name"] as String,
              location:
                  userData["email"] as String? ??
                  userData["location"] as String,
              accountStatus:
                  _showSubscriptionFeatures
                      ? userData["accountStatus"] as String
                      : "Free",
              onEditPressed: _editName,
            ),

            SizedBox(height: 3.h),

            // Personal Information Section
            SettingsSectionWidget(
              title: 'Personal Information',
              children: [
                // Show email if available
                if (userData["email"] != null &&
                    (userData["email"] as String).isNotEmpty)
                  SettingsItemWidget(
                    iconName: 'email',
                    title: 'Email Address',
                    subtitle: userData["email"] as String,
                    showArrow: false,
                  ),
                SettingsItemWidget(
                  iconName: 'track_changes',
                  title: 'Sun Exposure Goals',
                  subtitle: 'Set and adjust your daily/weekly targets',
                  onTap: _editGoals,
                ),
                SettingsItemWidget(
                  iconName: 'palette',
                  title: 'Skin Type',
                  subtitle: userData["skinType"] as String,
                  onTap: _editSkinType,
                ),
                SettingsItemWidget(
                  iconName: 'local_fire_department',
                  title: 'Burn Sensitivity',
                  subtitle: 'Level ${userData["burnSensitivity"]} of 5',
                  onTap: _editBurnSensitivity,
                ),
                SettingsItemWidget(
                  iconName: 'cake',
                  title: 'Age Range',
                  subtitle: userData["ageRange"] as String,
                  onTap: _editAgeRange,
                ),
                SettingsItemWidget(
                  iconName: 'monitor_weight',
                  title: 'BMI Range',
                  subtitle: userData["bmiRange"] as String,
                  onTap: _editBMI,
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Location Settings Section
            SettingsSectionWidget(
              title: 'Location Settings',
              children: [
                SettingsItemWidget(
                  iconName: 'location_on',
                  title: 'Current Location',
                  subtitle: userData["location"] as String,
                  onTap: _editLocationSettings,
                ),
                SettingsItemWidget(
                  iconName: 'schedule',
                  title: 'Timezone',
                  subtitle: userData["timezone"] as String,
                  onTap: _editLocationSettings,
                ),
                SettingsItemWidget(
                  iconName: 'gps_fixed',
                  title: 'GPS Accuracy',
                  subtitle: '${userData["gpsAccuracy"]} precision',
                  trailing: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.getSuccessColor(
                        true,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Active',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.getSuccessColor(true),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  onTap: _editLocationSettings,
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Notification Preferences Section
            SettingsSectionWidget(
              title: 'Notification Preferences',
              children: [
                ToggleItemWidget(
                  iconName: 'wb_sunny',
                  title: 'Optimal Window Alerts',
                  subtitle:
                      'Get notified 30-60 minutes before your optimal sun exposure window',
                  value: _optimalWindowAlerts,
                  onChanged: (value) {
                    setState(() {
                      _optimalWindowAlerts = value;
                    });
                    _showToast(
                      'Optimal window alerts ${value ? 'enabled' : 'disabled'}',
                    );
                  },
                ),
                ToggleItemWidget(
                  iconName: 'notifications',
                  title: 'Missed Session Reminders',
                  subtitle:
                      'Gentle nudges with alternative suggestions when you miss a window',
                  value: _missedSessionReminders,
                  onChanged: (value) {
                    setState(() {
                      _missedSessionReminders = value;
                    });
                    _showToast(
                      'Missed session reminders ${value ? 'enabled' : 'disabled'}',
                    );
                  },
                ),
                ToggleItemWidget(
                  iconName: 'school',
                  title: 'Educational Content',
                  subtitle: 'Receive UV safety tips and wellness insights',
                  value: _educationalContent,
                  onChanged: (value) {
                    setState(() {
                      _educationalContent = value;
                    });
                    _showToast(
                      'Educational content ${value ? 'enabled' : 'disabled'}',
                    );
                  },
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Integration Settings Section - HIDDEN
            // SettingsSectionWidget(
            //   title: 'Health Integrations',
            //   children: [
            //     ToggleItemWidget(
            //       iconName: 'favorite',
            //       title: 'Apple Health',
            //       subtitle: 'Sync sun exposure data with Apple HealthKit',
            //       value: _appleHealthSync,
            //       onChanged: (value) {
            //         setState(() {
            //           _appleHealthSync = value;
            //         });
            //         _showToast(
            //             'Apple Health sync ${value ? 'enabled' : 'disabled'}');
            //       },
            //     ),
            //     ToggleItemWidget(
            //       iconName: 'fitness_center',
            //       title: 'Google Fit',
            //       subtitle:
            //           'Connect with Google Fit for comprehensive health tracking',
            //       value: _googleFitSync,
            //       onChanged: (value) {
            //         setState(() {
            //           _googleFitSync = value;
            //         });
            //         _showToast(
            //             'Google Fit sync ${value ? 'enabled' : 'disabled'}');
            //       },
            //     ),
            //   ],
            // ),
            SizedBox(height: 2.h),

            // SUBSCRIPTION STATUS - HIDDEN BUT PRESERVED
            if (_showSubscriptionFeatures) ...[
              SettingsSectionWidget(
                title: 'Subscription',
                children: [
                  Container(
                    padding: EdgeInsets.all(4.w),
                    child: SubscriptionCardWidget(
                      planName: userData["subscriptionPlan"] as String,
                      planPrice: userData["subscriptionPrice"] as String,
                      planDescription:
                          userData["subscriptionDescription"] as String,
                      isActive: userData["subscriptionPlan"] == "Pro",
                      onUpgradePressed: _upgradeToPro,
                      onManagePressed: _manageSubscription,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
            ],

            SizedBox(height: 2.h),

            // Data Management Section
            SettingsSectionWidget(
              title: 'Data Management',
              children: [
                // EXPORT DATA FEATURE - Hidden but preserved for future use
                if (_showExportDataFeature)
                  SettingsItemWidget(
                    iconName: 'download',
                    title: 'Export Data',
                    subtitle: 'Download your sun exposure data as CSV file',
                    onTap: _exportData,
                  ),
                SettingsItemWidget(
                  iconName: 'delete_forever',
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account and all data',
                  onTap: _showDeleteAccountDialog,
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Legal Section
            SettingsSectionWidget(
              title: 'Legal & Support',
              children: [
                SettingsItemWidget(
                  iconName: 'description',
                  title: 'Terms of Service',
                  subtitle: 'Read our terms and conditions',
                  onTap: _openTermsOfService,
                ),
                SettingsItemWidget(
                  iconName: 'privacy_tip',
                  title: 'Privacy Policy',
                  subtitle: 'Learn how we protect your data',
                  onTap: _openPrivacyPolicy,
                ),
                SettingsItemWidget(
                  iconName: 'medical_services',
                  title: 'Medical Disclaimer',
                  subtitle: 'Important health and safety information',
                  onTap: _openMedicalDisclaimer,
                ),
                SettingsItemWidget(
                  iconName: 'support',
                  title: 'Support',
                  subtitle: 'Get help and contact our team',
                  onTap: _contactSupport,
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Version Information
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  Text(
                    'Sunbeam v1.2.0',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Member since ${_formatDate(userData["joinDate"] as String)}',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '${userData["totalSessions"]} sessions logged • ${userData["streakDays"]} day streak',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 4.h),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedNavIndex,
      onTap: (index) {
        if (index == _selectedNavIndex) return; // Don't navigate to same tab

        setState(() {
          _selectedNavIndex = index;
        });

        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home-screen');
            break;
          case 1:
            Navigator.pushNamed(context, '/log-session-screen');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/insights-screen');
            break;
          case 3:
            // Already on profile
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      selectedItemColor: AppTheme.lightTheme.primaryColor,
      unselectedItemColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
      elevation: 8,
      items: [
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'home',
            color:
                _selectedNavIndex == 0
                    ? AppTheme.lightTheme.primaryColor
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'add_circle_outline',
            color:
                _selectedNavIndex == 1
                    ? AppTheme.lightTheme.primaryColor
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Log',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'insights',
            color:
                _selectedNavIndex == 2
                    ? AppTheme.lightTheme.primaryColor
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Insights',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'person',
            color:
                _selectedNavIndex == 3
                    ? AppTheme.lightTheme.primaryColor
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Profile',
        ),
      ],
    );
  }

  void _editName() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => NameEditScreen(
              currentName: userData["name"] as String,
              onNameChanged: (newName) async {
                // Save to SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_name', newName);

                setState(() {
                  userData["name"] = newName;
                });
                _showToast('Name updated successfully');
              },
            ),
      ),
    );
  }

  void _editSkinType() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SkinTypeEditScreen(
              currentSkinType: userData["skinType"] as String?,
              onSkinTypeChanged: (newSkinType) {
                setState(() {
                  userData["skinType"] = newSkinType;
                });
              },
            ),
      ),
    );
  }

  void _editBurnSensitivity() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BurnSensitivityEditScreen(
              currentSensitivity: 'Level ${userData["burnSensitivity"]} of 5',
              onSensitivityChanged: (newLevel) {
                setState(() {
                  userData["burnSensitivity"] = newLevel;
                });
              },
            ),
      ),
    );
  }

  void _editAgeRange() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AgeRangeEditScreen(
              currentAgeRange: userData["ageRange"] as String?,
              onAgeRangeChanged: (newAgeRange) {
                setState(() {
                  userData["ageRange"] = newAgeRange;
                });
              },
            ),
      ),
    );
  }

  void _editBMI() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => BMISelectionScreen(
              initialBMIRange: userData["bmiRange"] as String?,
              onBMISelected: (selectedBMI) {
                setState(() {
                  userData["bmiRange"] = selectedBMI;
                });
                _showToast('BMI range updated to $selectedBMI');
              },
            ),
      ),
    );
  }

  void _editLocationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => LocationSettingsScreen(
              currentLocation: userData["location"] as String,
              currentTimezone: userData["timezone"] as String,
              currentGpsAccuracy: userData["gpsAccuracy"] as String,
              onLocationChanged: (location, timezone, gpsAccuracy) async {
                setState(() {
                  userData["location"] = location;
                  userData["timezone"] = timezone;
                  userData["gpsAccuracy"] = gpsAccuracy;
                });
              },
            ),
      ),
    );
  }

  void _editLocation() {
    _editLocationSettings();
  }

  void _editTimezone() {
    _editLocationSettings();
  }

  void _editGoals() {
    // Mock current goals data - this would be loaded from storage in real app
    Map<String, dynamic> currentGoals = {
      'primary_goal_type': 'sessions_per_day',
      'enable_secondary_goal': true,
      'secondary_goal_type': 'minutes_per_session',
      'sessions_per_day': 2,
      'minutes_per_session': 15,
      'sessions_per_week': 14,
      'total_minutes_per_week': 210,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => GoalEditScreen(
              currentGoals: currentGoals,
              onGoalsChanged: (newGoals) {
                _showToast('Goals updated successfully');
                // In real app, save to shared preferences or database here
              },
            ),
      ),
    );
  }

  // SUBSCRIPTION METHODS - PRESERVED FOR FUTURE USE
  void _upgradeToPro() {
    _showToast('Upgrade to Pro - Redirecting to subscription page');
  }

  void _manageSubscription() {
    _showToast('Manage subscription - Redirecting to billing management');
  }

  // EXPORT DATA METHODS - PRESERVED FOR FUTURE USE
  Future<void> _exportData() async {
    try {
      // Generate CSV data
      final csvData = _generateCSVData();
      final fileName =
          'sunbeam_data_${DateTime.now().millisecondsSinceEpoch}.csv';

      if (kIsWeb) {
        // Web implementation
        final bytes = utf8.encode(csvData);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor =
            html.AnchorElement(href: url)
              ..setAttribute("download", fileName)
              ..click();
        html.Url.revokeObjectUrl(url);
        _showToast('Data exported successfully');
      } else {
        // Mobile implementation
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(csvData);
        _showToast('Data exported to ${file.path}');
      }
    } catch (e) {
      _showToast('Export failed. Please try again.');
    }
  }

  String _generateCSVData() {
    final header = 'Date,Duration,UV Index,Mood,Energy,Notes\n';
    final sampleData = '''2024-10-29,15,6,4,4,Morning session in garden
2024-10-28,20,7,5,5,Perfect weather conditions
2024-10-27,12,5,3,4,Cloudy but still beneficial
2024-10-26,18,8,4,5,Used SPF 30 sunscreen
2024-10-25,25,6,5,4,Longer session felt great''';
    return header + sampleData;
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Account',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to permanently delete your account? This action cannot be undone and all your data will be lost.',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showToast('Account deletion initiated - Check your email');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.colorScheme.error,
                foregroundColor: AppTheme.lightTheme.colorScheme.onError,
              ),
              child: Text(
                'Delete',
                style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openTermsOfService() {
    _showToast('Opening Terms of Service in web view');
  }

  void _openPrivacyPolicy() {
    _showToast('Opening Privacy Policy in web view');
  }

  void _openMedicalDisclaimer() {
    _showToast('Opening Medical Disclaimer in web view');
  }

  void _contactSupport() {
    _showToast('Opening support contact options');
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      textColor: AppTheme.lightTheme.colorScheme.onSurface,
    );
  }
}
