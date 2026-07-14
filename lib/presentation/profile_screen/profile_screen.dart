import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import '../legal/legal_document_screen.dart';
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
import './widgets/toggle_item_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedNavIndex = 3; // Set to profile tab

  String _appVersion = '';

  // User data - loaded from Supabase and SharedPreferences
  Map<String, dynamic> userData = {
    "name": "User",
    "email": "",
    "location": "Location not set",
    "accountStatus": "Free",
    "skinType": "Type III - Light Brown",
    "burnSensitivity": 3,
    "ageRange": "25-34",
    "bmiRange": "18.5-24.9",
    "timezone": "Local time",
    "gpsAccuracy": "High",
    "joinDate": "",
    "totalSessions": 0,
  };

  // Settings state
  bool _optimalWindowAlerts = true;
  bool _missedSessionReminders = true;
  bool _educationalContent = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAppVersion();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _optimalWindowAlerts =
          prefs.getBool(NotificationService.prefOptimalWindowAlerts) ?? true;
      _missedSessionReminders =
          prefs.getBool(NotificationService.prefMissedSessionReminders) ??
              true;
      _educationalContent =
          prefs.getBool(NotificationService.prefEducationalContent) ?? true;
    });
  }

  Future<void> _setOptimalWindowAlerts(bool value) async {
    setState(() => _optimalWindowAlerts = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationService.prefOptimalWindowAlerts, value);
    if (value) {
      final granted = await NotificationService.instance.requestPermissions();
      _showToast(granted
          ? 'Optimal window alerts enabled'
          : 'Enable notifications in system settings to receive alerts');
    } else {
      await NotificationService.instance.cancelOptimalWindowAlert();
      _showToast('Optimal window alerts disabled');
    }
  }

  Future<void> _setMissedSessionReminders(bool value) async {
    setState(() => _missedSessionReminders = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        NotificationService.prefMissedSessionReminders, value);
    if (value) {
      final granted = await NotificationService.instance.requestPermissions();
      await NotificationService.instance.scheduleMissedSessionReminder();
      _showToast(granted
          ? 'Missed session reminders enabled'
          : 'Enable notifications in system settings to receive reminders');
    } else {
      await NotificationService.instance.cancelMissedSessionReminder();
      _showToast('Missed session reminders disabled');
    }
  }

  Future<void> _setEducationalContent(bool value) async {
    setState(() => _educationalContent = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(NotificationService.prefEducationalContent, value);
    _showToast(
        'Educational content ${value ? 'enabled' : 'hidden on home screen'}');
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {
      // Version footer simply stays empty if unavailable.
    }
  }

  Future<void> _loadUserData() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user != null) {
        // Name + email from auth
        final name = (user.userMetadata?['full_name'] as String?)?.isNotEmpty == true
            ? user.userMetadata!['full_name'] as String
            : user.email?.split('@')[0] ?? 'User';

        // Profile row for skin type and join date
        final profile = await client
            .from('user_profiles')
            .select('skin_type, created_at')
            .eq('id', user.id)
            .maybeSingle();

        // Total session count
        final sessions = await client
            .from('sun_sessions')
            .select('id')
            .eq('user_id', user.id);
        final totalSessions = (sessions as List).length;

        final skinTypeInt = (profile?['skin_type'] as int?) ?? 2;
        final joinDate = profile?['created_at'] != null
            ? (profile!['created_at'] as String).substring(0, 10)
            : '2024-01-01';

        if (mounted) {
          setState(() {
            userData['name'] = name;
            userData['email'] = user.email ?? '';
            userData['skinType'] = 'Type ${_skinTypeLabel(skinTypeInt)}';
            userData['joinDate'] = joinDate;
            userData['totalSessions'] = totalSessions;
          });
        }
      }

      // Supplement with SharedPreferences for location (set by LocationService)
      final prefs = await SharedPreferences.getInstance();
      final savedLocation = prefs.getString('user_location');
      final savedTimezone = prefs.getString('user_timezone');
      final savedGpsAccuracy = prefs.getString('gps_accuracy');

      if (mounted) {
        setState(() {
          if (savedLocation?.isNotEmpty == true) userData['location'] = savedLocation!;
          if (savedTimezone?.isNotEmpty == true) userData['timezone'] = savedTimezone!;
          if (savedGpsAccuracy?.isNotEmpty == true) userData['gpsAccuracy'] = savedGpsAccuracy!;
        });
      }

      if (savedLocation == null || savedLocation.isEmpty) {
        _loadLocationFromSupabase();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  String _skinTypeLabel(int type) {
    const labels = {1: 'I', 2: 'II', 3: 'III', 4: 'IV', 5: 'V', 6: 'VI'};
    return labels[type] ?? 'II';
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Sign Out',
          style: AppTheme.lightTheme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sign Out',
              style: TextStyle(color: AppTheme.lightTheme.colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      if (mounted) _showToast('Sign out failed. Please try again.');
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
      debugPrint('Error loading location from Supabase: $e');
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

            ProfileHeaderWidget(
              userName: userData["name"] as String,
              location:
                  userData["email"] as String? ??
                  userData["location"] as String,
              accountStatus: userData["accountStatus"] as String,
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
                  onChanged: _setOptimalWindowAlerts,
                ),
                ToggleItemWidget(
                  iconName: 'notifications',
                  title: 'Missed Session Reminders',
                  subtitle:
                      'Gentle nudges with alternative suggestions when you miss a window',
                  value: _missedSessionReminders,
                  onChanged: _setMissedSessionReminders,
                ),
                ToggleItemWidget(
                  iconName: 'school',
                  title: 'Educational Content',
                  subtitle:
                      'Show UV safety tips and insights on the home screen',
                  value: _educationalContent,
                  onChanged: _setEducationalContent,
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Account Section
            if (Supabase.instance.client.auth.currentUser != null)
              SettingsSectionWidget(
                title: 'Account',
                children: [
                  SettingsItemWidget(
                    iconName: 'logout',
                    title: 'Sign Out',
                    subtitle: 'Sign out of your Sunbeam account',
                    onTap: _signOut,
                  ),
                ],
              ),

            // Data Management Section (only relevant for signed-in users)
            if (Supabase.instance.client.auth.currentUser != null) ...[
              SizedBox(height: 2.h),
              SettingsSectionWidget(
                title: 'Data Management',
                children: [
                  SettingsItemWidget(
                    iconName: 'delete_forever',
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account and all data',
                    onTap: _showDeleteAccountDialog,
                  ),
                ],
              ),
            ],

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
                  if (_appVersion.isNotEmpty)
                    Text(
                      'Sunbeam v$_appVersion',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if ((userData["joinDate"] as String).isNotEmpty) ...[
                    SizedBox(height: 1.h),
                    Text(
                      'Member since ${_formatDate(userData["joinDate"] as String)}',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '${userData["totalSessions"]} sessions logged',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
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

  Future<void> _editGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final currentGoals = {
      'primary_goal_type':
          prefs.getString('primary_goal_type') ?? 'sessions_per_day',
      'enable_secondary_goal': prefs.getBool('enable_secondary_goal') ?? true,
      'secondary_goal_type':
          prefs.getString('secondary_goal_type') ?? 'minutes_per_session',
      'sessions_per_day': prefs.getInt('sessions_per_day') ?? 2,
      'minutes_per_session': prefs.getInt('minutes_per_session') ?? 15,
      'sessions_per_week': prefs.getInt('sessions_per_week') ?? 14,
      'total_minutes_per_week': prefs.getInt('total_minutes_per_week') ?? 210,
    };

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => GoalEditScreen(
              currentGoals: currentGoals,
              onGoalsChanged: (newGoals) {
                // GoalEditScreen persists to SharedPreferences itself.
                _showToast('Goals updated successfully');
              },
            ),
      ),
    );
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
                _deleteAccount();
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

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final client = Supabase.instance.client;
      await client.rpc('delete_account');
      await client.auth.signOut();

      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss progress dialog
      _showToast('Your account and data have been deleted');
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.welcomeScreen,
        (route) => false,
      );
    } catch (e) {
      debugPrint('Error deleting account: $e');
      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss progress dialog
      _showToast('Account deletion failed. Please try again or contact support.');
    }
  }

  void _openLegalDocument(String title, String assetPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LegalDocumentScreen(title: title, assetPath: assetPath),
      ),
    );
  }

  void _openTermsOfService() {
    _openLegalDocument(
        'Terms of Service', LegalDocumentScreen.termsOfServiceAsset);
  }

  void _openPrivacyPolicy() {
    _openLegalDocument(
        'Privacy Policy', LegalDocumentScreen.privacyPolicyAsset);
  }

  void _openMedicalDisclaimer() {
    _openLegalDocument(
        'Medical Disclaimer', LegalDocumentScreen.medicalDisclaimerAsset);
  }

  Future<void> _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'jordan@thesmallbizlab.com',
      query: 'subject=Sunbeam Support',
    );
    try {
      final launched = await launchUrl(uri);
      if (!launched) {
        _showToast('Email us at jordan@thesmallbizlab.com');
      }
    } catch (_) {
      _showToast('Email us at jordan@thesmallbizlab.com');
    }
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
