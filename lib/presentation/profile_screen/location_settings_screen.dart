import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/location_service.dart';
import '../../services/weather_service.dart';
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

  // Real GPS state (loaded async, shown in the GPS Status card)
  bool _gpsActive = false;
  double? _lastFixAccuracy;
  DateTime? _lastFixAt;
  bool _manualLocation = false;

  // Manual location search
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.currentLocation;
    _currentTimezone = widget.currentTimezone;
    _gpsAccuracy = widget.currentGpsAccuracy;
    _highPrecisionGPS = _gpsAccuracy.toLowerCase().contains('high');
    _loadGpsStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGpsStatus() async {
    final locationService = LocationService.instance;
    final serviceEnabled = await locationService.isLocationServiceEnabled();
    final hasPermission = await locationService.hasLocationPermission();

    final prefs = await SharedPreferences.getInstance();
    final accuracy =
        prefs.getDouble(LocationService.prefLastFixAccuracy);
    final fixAtRaw = prefs.getString(LocationService.prefLastFixAt);
    final manual =
        prefs.getBool(LocationService.prefManualLocation) ?? false;
    final highPrecision =
        prefs.getBool(LocationService.prefHighPrecisionGps);

    if (!mounted) return;
    setState(() {
      _gpsActive = serviceEnabled && hasPermission;
      _lastFixAccuracy = accuracy;
      _lastFixAt = fixAtRaw != null ? DateTime.tryParse(fixAtRaw) : null;
      _manualLocation = manual;
      if (highPrecision != null) {
        _highPrecisionGPS = highPrecision;
        _gpsAccuracy = highPrecision ? 'High' : 'Balanced';
      }
    });
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
                                  style: AppTheme
                                      .lightTheme.textTheme.bodyMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_manualLocation)
                                  Text(
                                    'Set manually — tap refresh to use GPS',
                                    style: AppTheme
                                        .lightTheme.textTheme.bodySmall
                                        ?.copyWith(
                                      color:
                                          AppTheme.lightTheme.primaryColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (_isLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
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
                                  style: AppTheme
                                      .lightTheme.textTheme.bodyMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
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
            SettingsSectionWidget(
              title: 'Set Location Manually',
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wrong city detected? Search for your city to override GPS.',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme
                              .lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 1.5.h),
                      TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _searchCity(),
                        decoration: InputDecoration(
                          hintText: 'Search city (e.g. Mesa)',
                          isDense: true,
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.arrow_forward,
                                      size: 20),
                                  onPressed: _searchCity,
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      ..._searchResults.map(
                        (result) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: CustomIconWidget(
                            iconName: 'location_city',
                            color: AppTheme.lightTheme.primaryColor,
                            size: 20,
                          ),
                          title: Text(
                            _displayNameFor(result),
                            style:
                                AppTheme.lightTheme.textTheme.bodyMedium,
                          ),
                          subtitle: result['country'] != null
                              ? Text(
                                  result['country'] as String,
                                  style: AppTheme
                                      .lightTheme.textTheme.bodySmall,
                                )
                              : null,
                          onTap: () => _selectManualLocation(result),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
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
                              color: _gpsStatusColor,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            _gpsStatusLabel,
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: _gpsStatusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        _gpsAccuracyDescription,
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
            SizedBox(height: 2.h),
            Container(
              margin: EdgeInsets.all(4.w),
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest
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
                    '• If GPS detects the wrong city, use manual search to set it yourself\n'
                    '• High precision GPS provides better accuracy but uses more battery\n'
                    '• On iPhone, enable "Precise Location" in Settings for exact results\n'
                    '• Location data is used for weather forecasts and UV index calculations\n'
                    '• Your location data is stored securely and never shared',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
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

      if (!await locationService.isLocationServiceEnabled()) {
        _showToast(
            'Location service is disabled. Please enable it in settings.');
        await locationService.openLocationSettings();
        setState(() => _isLoading = false);
        return;
      }

      if (!await locationService.requestLocationPermission()) {
        _showToast(
            'Location permission denied. Please grant permission in settings.');
        await locationService.openAppSettings();
        setState(() => _isLoading = false);
        return;
      }

      final position = await locationService.getCurrentLocation();
      if (position == null) {
        _showToast('Unable to get current location. Please try again.');
        setState(() => _isLoading = false);
        return;
      }

      final lat = position.latitude;
      final lng = position.longitude;

      // Device geocoder first; fall back to the web-capable reverse
      // geocode API so refresh also works on web.
      String? address =
          await locationService.getAddressFromCoordinates(lat, lng);
      address ??= await WeatherService.instance.getLocationName(lat, lng);

      if (address != null) {
        final timezone = await locationService.getTimezone(lat, lng);

        final displayLocation = address;
        final displayTimezone =
            LocationService.formatTimezoneLabel(timezone);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_location', displayLocation);
        await prefs.setString('user_timezone', displayTimezone);
        await prefs.setDouble('user_latitude', lat);
        await prefs.setDouble('user_longitude', lng);
        // A GPS refresh always clears any manual override.
        await prefs.setBool(LocationService.prefManualLocation, false);

        await locationService.saveLocationToSupabase(position);

        setState(() {
          _currentLocation = displayLocation;
          _currentTimezone = displayTimezone;
          _manualLocation = false;
        });
        await _loadGpsStatus();

        widget.onLocationChanged(
            _currentLocation, _currentTimezone, _gpsAccuracy);

        _showToast('Location updated successfully');
      } else {
        _showToast('Unable to get location address. Please try again.');
      }
    } catch (e) {
      debugPrint('Error refreshing location: $e');
      _showToast(
          'Error getting location. Please check your connection and try again.');
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('high_precision_gps', value);
    await prefs.setString('gps_accuracy', _gpsAccuracy);

    widget.onLocationChanged(_currentLocation, _currentTimezone, _gpsAccuracy);

    _showToast('GPS accuracy set to ${_gpsAccuracy.toLowerCase()} precision');
  }

  // ---------- Manual location search ----------

  Future<void> _searchCity() async {
    final query = _searchController.text.trim();
    if (query.length < 2 || _isSearching) return;

    setState(() => _isSearching = true);
    try {
      final results = await WeatherService.instance.searchLocations(query);
      if (!mounted) return;
      setState(() => _searchResults = results);
      if (results.isEmpty) {
        _showToast('No cities found for "$query"');
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  String _displayNameFor(Map<String, dynamic> result) {
    final name = result['name'] as String;
    final region = result['region'] as String?;
    final country = result['country'] as String?;
    if (region != null && region.isNotEmpty) return '$name, $region';
    if (country != null && country.isNotEmpty) return '$name, $country';
    return name;
  }

  Future<void> _selectManualLocation(Map<String, dynamic> result) async {
    final displayLocation = _displayNameFor(result);
    final lat = result['latitude'] as double;
    final lng = result['longitude'] as double;
    final displayTimezone =
        LocationService.formatTimezoneLabel(result['timezone'] as String?);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_location', displayLocation);
    await prefs.setString('user_timezone', displayTimezone);
    await prefs.setDouble('user_latitude', lat);
    await prefs.setDouble('user_longitude', lng);
    await prefs.setBool(LocationService.prefManualLocation, true);

    if (!mounted) return;
    setState(() {
      _currentLocation = displayLocation;
      _currentTimezone = displayTimezone;
      _manualLocation = true;
      _searchResults = [];
      _searchController.clear();
    });
    FocusScope.of(context).unfocus();

    widget.onLocationChanged(_currentLocation, _currentTimezone, _gpsAccuracy);
    _showToast('Location set to $displayLocation');
  }

  // ---------- GPS status display ----------

  Color get _gpsStatusColor {
    if (!_gpsActive) return AppTheme.lightTheme.colorScheme.error;
    return AppTheme.getSuccessColor(true);
  }

  String get _gpsStatusLabel {
    if (!_gpsActive) return 'Inactive — check location permissions';
    if (_manualLocation) return 'Standby (manual location in use)';
    return 'Active';
  }

  String get _gpsAccuracyDescription {
    final accuracy = _lastFixAccuracy;
    if (accuracy == null) return 'No GPS fix recorded yet';
    final quality = accuracy <= 50
        ? 'excellent'
        : accuracy <= 200
            ? 'good'
            : accuracy <= LocationService.acceptableAccuracyMeters
                ? 'fair'
                : 'approximate — displayed city may be off';
    final when = _lastFixAt != null ? ' · ${_timeAgo(_lastFixAt!)}' : '';
    return 'Last fix: ±${accuracy.round()} m ($quality)$when';
  }

  String _timeAgo(DateTime time) {
    final elapsed = DateTime.now().difference(time);
    if (elapsed.inMinutes < 1) return 'just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes} min ago';
    if (elapsed.inHours < 24) return '${elapsed.inHours} hr ago';
    return '${elapsed.inDays} days ago';
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
