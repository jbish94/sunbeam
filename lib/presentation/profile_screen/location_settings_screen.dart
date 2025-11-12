import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/settings_item_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/toggle_item_widget.dart';

class LocationSettingsScreen extends StatefulWidget {
  final String currentLocation;
  final String currentTimezone;
  final String currentGpsAccuracy;
  final Function(String location, String timezone, String gpsAccuracy)
      onLocationChanged;

  const LocationSettingsScreen({
    Key? key,
    required this.currentLocation,
    required this.currentTimezone,
    required this.currentGpsAccuracy,
    required this.onLocationChanged,
  }) : super(key: key);

  @override
  State<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  bool _isLoading = false;
  bool _highPrecisionGPS = true;
  String _currentLocation = '';
  String _currentTimezone = '';
  String _gpsAccuracy = '';

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.currentLocation;
    _currentTimezone = widget.currentTimezone;
    _gpsAccuracy = widget.currentGpsAccuracy;
    _highPrecisionGPS = _gpsAccuracy.toLowerCase().contains('high');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Location Settings',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 2.h),

            // Location Information Section
            SettingsSectionWidget(
              title: 'Current Location',
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'location_on',
                            color: AppTheme.lightTheme.primaryColor,
                            size: 20,
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Location',
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  _currentLocation,
                                  style: AppTheme.lightTheme.textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          if (_isLoading) ...[
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.lightTheme.primaryColor,
                                ),
                              ),
                            ),
                          ] else ...[
                            IconButton(
                              onPressed: _refreshLocation,
                              icon: CustomIconWidget(
                                iconName: 'refresh',
                                color: AppTheme.lightTheme.primaryColor,
                                size: 20,
                              ),
                              tooltip: 'Refresh Location',
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'schedule',
                            color: AppTheme.lightTheme.primaryColor,
                            size: 20,
                          ),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Timezone',
                                  style: AppTheme.lightTheme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  _currentTimezone,
                                  style: AppTheme.lightTheme.textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // GPS Accuracy Settings
            SettingsSectionWidget(
              title: 'GPS Accuracy',
              children: [
                ToggleItemWidget(
                  iconName: 'gps_fixed',
                  title: 'High Precision GPS',
                  subtitle: _highPrecisionGPS
                      ? 'Using high precision mode for better accuracy'
                      : 'Using balanced mode to save battery',
                  value: _highPrecisionGPS,
                  onChanged: _toggleGPSAccuracy,
                ),
                Container(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GPS Status',
                        style: AppTheme.lightTheme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.getSuccessColor(true),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Active',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme.getSuccessColor(true),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Current accuracy: ${_gpsAccuracy.toLowerCase()} precision',
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Information Section
            Container(
              margin: EdgeInsets.all(4.w),
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme
                    .lightTheme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'info',
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'About Location Settings',
                        style: AppTheme.lightTheme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    '• Refreshing location will update your current position and timezone\n'
                    '• High precision GPS provides better accuracy but uses more battery\n'
                    '• Location data is used for weather forecasts and UV index calculations\n'
                    '• Your location data is stored securely and never shared',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color:
                          AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshLocation() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final locationService = LocationService.instance;

      // Check if location service is enabled
      if (!await locationService.isLocationServiceEnabled()) {
        _showToast(
          'Location service is disabled. Please enable it in settings.',
        );
        await locationService.openLocationSettings();
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Request permission
      if (!await locationService.requestLocationPermission()) {
        _showToast(
          'Location permission denied. Please grant permission in settings.',
        );
        await locationService.openAppSettings();
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get current location (now returns a Map with doubles)
      final position = await locationService.getCurrentLocation();
      if (position == null) {
        _showToast('Unable to get current location. Please try again.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final lat = (position['latitude'] as num).toDouble();
      final lng = (position['longitude'] as num).toDouble();

      // Get address from coordinates
      final address = await locationService.getAddressFromCoordinates(lat, lng);

      if (address != null) {
        // Get timezone for the location
        final timezone = await locationService.getTimezone(lat, lng);

        // Update location data
        final displayLocation = address;
        final displayTimezone = _formatTimezone(timezone ?? 'UTC');

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_location', displayLocation);
        await prefs.setString('user_timezone', displayTimezone);
        await prefs.setDouble('user_latitude', lat);
        await prefs.setDouble('user_longitude', lng);

        // Save to Supabase if available (accepts the same map-shaped position)
        await locationService.saveLocationToSupabase(
          position,
          address: address,
        );

        setState(() {
          _currentLocation = displayLocation;
          _currentTimezone = displayTimezone;
        });

        // Notify parent
        widget.onLocationChanged(
          _currentLocation,
          _currentTimezone,
          _gpsAccuracy,
        );

        _showToast('Location updated successfully');
      } else {
        _showToast('Unable to get location address. Please try again.');
      }
    } catch (e) {
      print('Error refreshing location: $e');
      _showToast(
        'Error getting location. Please check your connection and try again.',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleGPSAccuracy(bool value) async {
    setState(() {
      _highPrecisionGPS = value;
      _gpsAccuracy = value ? 'High' : 'Balanced';
    });

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('high_precision_gps', value);
    await prefs.setString('gps_accuracy', _gpsAccuracy);

    // Update parent
    widget.onLocationChanged(_currentLocation, _currentTimezone, _gpsAccuracy);

    _showToast('GPS accuracy set to ${_gpsAccuracy.toLowerCase()} precision');
  }

  String _formatTimezone(String timezone) {
    final timezoneMapping = <String, String>{
      'America/Phoenix': 'MST (GMT-7)',
      'America/Denver': 'MST (GMT-7)',
      'America/Los_Angeles': 'PST (GMT-8)',
      'America/New_York': 'EST (GMT-5)',
      'America/Chicago': 'CST (GMT-6)',
      'Europe/London': 'GMT (GMT+0)',
      'Europe/Berlin': 'CET (GMT+1)',
      'Asia/Tokyo': 'JST (GMT+9)',
      'Australia/Sydney': 'AEDT (GMT+11)',
      'UTC': 'UTC (GMT+0)',
    };

    return timezoneMapping[timezone] ?? 'Local Time';
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
