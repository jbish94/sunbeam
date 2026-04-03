import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/session_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedNavIndex = 1;
  bool _isLoading = false;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final sessions = await SessionService.instance.getSessionHistory(
        limit: 200,
      );
      if (mounted) {
        setState(() {
          _sessions =
              sessions.where((s) => s['status'] == 'completed').toList();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Session History',
          style: AppTheme.lightTheme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: user == null ? _buildGuestState() : _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
            color: AppTheme.lightTheme.primaryColor),
      );
    }

    if (_sessions.isEmpty) {
      return _buildEmptyState();
    }

    // Group sessions by date
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final s in _sessions) {
      final dt = DateTime.parse(s['start_time'] as String).toLocal();
      final key = _formatDateHeader(dt);
      grouped.putIfAbsent(key, () => []).add(s);
    }

    return RefreshIndicator(
      onRefresh: _loadSessions,
      color: AppTheme.lightTheme.primaryColor,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        itemCount: grouped.length,
        itemBuilder: (context, i) {
          final dateLabel = grouped.keys.elementAt(i);
          final daySessions = grouped[dateLabel]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 2.h, bottom: 1.h),
                child: Text(
                  dateLabel,
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              ...daySessions.map((s) => _buildSessionCard(s)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final startDt =
        DateTime.parse(session['start_time'] as String).toLocal();
    final duration = (session['duration_minutes'] as int?) ?? 0;
    final uvAvg = (session['uv_index_avg'] as num?)?.toDouble();
    final moodBefore = session['mood_before'] as int?;
    final moodAfter = session['mood_after'] as int?;
    final energyBefore = session['energy_before'] as int?;
    final energyAfter = session['energy_after'] as int?;
    final notes = session['notes'] as String?;
    final protection =
        (session['protection_used'] as List?)?.cast<String>() ?? [];

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time + duration row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'schedule',
                    color: AppTheme.lightTheme.primaryColor,
                    size: 16,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    _formatTime(startDt),
                    style: AppTheme.lightTheme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'timer',
                    color:
                        AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 14,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '$duration min',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color:
                          AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 1.h),

          // UV badge + mood/energy delta row
          Row(
            children: [
              if (uvAvg != null) ...[
                _buildBadge(
                  icon: 'wb_sunny',
                  label: 'UV ${uvAvg.toStringAsFixed(1)}',
                  color: _uvColor(uvAvg),
                ),
                SizedBox(width: 2.w),
              ],
              if (moodBefore != null && moodAfter != null) ...[
                _buildDeltaBadge(
                  icon: 'mood',
                  label: 'Mood',
                  before: moodBefore,
                  after: moodAfter,
                ),
                SizedBox(width: 2.w),
              ],
              if (energyBefore != null && energyAfter != null)
                _buildDeltaBadge(
                  icon: 'bolt',
                  label: 'Energy',
                  before: energyBefore,
                  after: energyAfter,
                ),
            ],
          ),

          // Protection chips
          if (protection.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Wrap(
              spacing: 1.w,
              runSpacing: 0.5.h,
              children: protection
                  .map((p) => _buildChip(p))
                  .toList(),
            ),
          ],

          // Notes
          if (notes != null && notes.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomIconWidget(
                  iconName: 'notes',
                  color:
                      AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 14,
                ),
                SizedBox(width: 1.w),
                Expanded(
                  child: Text(
                    notes,
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(
      {required String icon,
      required String label,
      required Color color}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(iconName: icon, color: color, size: 12),
          SizedBox(width: 1.w),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeltaBadge({
    required String icon,
    required String label,
    required int before,
    required int after,
  }) {
    final delta = after - before;
    final color = delta > 0
        ? Colors.green
        : delta < 0
            ? Colors.red
            : AppTheme.lightTheme.colorScheme.onSurfaceVariant;
    final arrow = delta > 0 ? '↑' : delta < 0 ? '↓' : '→';
    return _buildBadge(
      icon: icon,
      label: '$label $arrow',
      color: color,
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'wb_sunny',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                .withValues(alpha: 0.4),
            size: 20.w,
          ),
          SizedBox(height: 3.h),
          Text(
            'No sessions yet',
            style: AppTheme.lightTheme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 1.h),
          Text(
            'Your logged sessions will appear here.',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 4.h),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, '/log-session-screen'),
            icon: const CustomIconWidget(
                iconName: 'add', color: Colors.white, size: 20),
            label: const Text('Log a Session'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'lock',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.4),
              size: 16.w,
            ),
            SizedBox(height: 3.h),
            Text(
              'Sign in to see your history',
              style: AppTheme.lightTheme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Create a free account to log sessions and track them over time.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/welcome-screen'),
                child: const Text('Sign In / Create Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedNavIndex,
      onTap: (index) {
        if (index == _selectedNavIndex) return;
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home-screen');
            break;
          case 1:
            break; // already here
          case 2:
            Navigator.pushReplacementNamed(context, '/insights-screen');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/profile-screen');
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      selectedItemColor: AppTheme.lightTheme.primaryColor,
      unselectedItemColor:
          AppTheme.lightTheme.colorScheme.onSurfaceVariant,
      elevation: 8,
      items: [
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'home',
            color: _selectedNavIndex == 0
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'history',
            color: _selectedNavIndex == 1
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'insights',
            color: _selectedNavIndex == 2
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Insights',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'person',
            color: _selectedNavIndex == 3
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          label: 'Profile',
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _formatDateHeader(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dt.year, dt.month, dt.day);

    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';

    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    if (h == 0) return '12:${m}AM';
    if (h < 12) return '${h}:${m}AM';
    if (h == 12) return '12:${m}PM';
    return '${h - 12}:${m}PM';
  }

  Color _uvColor(double uv) {
    if (uv < 3) return Colors.green;
    if (uv < 6) return Colors.orange;
    if (uv < 8) return Colors.deepOrange;
    return Colors.red;
  }
}
