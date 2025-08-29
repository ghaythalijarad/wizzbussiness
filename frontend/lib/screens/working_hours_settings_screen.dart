import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../core/design_system/golden_ratio_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/design_system/typography_system.dart';

class WorkingHoursSettingsScreen extends ConsumerStatefulWidget {
  final Business business;

  const WorkingHoursSettingsScreen({Key? key, required this.business})
      : super(key: key);

  @override
  ConsumerState<WorkingHoursSettingsScreen> createState() =>
      _WorkingHoursSettingsScreenState();
}

class _WorkingHoursSettingsScreenState
    extends ConsumerState<WorkingHoursSettingsScreen> {
  bool _isLoading = false;

  final Map<String, Map<String, dynamic>> _workingHours = {
    'monday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '21:00'},
    'tuesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '21:00'},
    'wednesday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '21:00'},
    'thursday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '21:00'},
    'friday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '21:00'},
    'saturday': {'isOpen': true, 'openTime': '09:00', 'closeTime': '21:00'},
    'sunday': {'isOpen': false, 'openTime': '09:00', 'closeTime': '21:00'},
  };

  final List<String> _daysOrder = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];
  final Map<String, String> _dayNames = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
  };

  @override
  void initState() {
    super.initState();
    _loadWorkingHours();
  }

  Future<void> _loadWorkingHours() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final hours =
          await apiService.getBusinessWorkingHours(widget.business.id);

      if (mounted && hours['workingHours'] != null) {
        setState(() {
          final loadedHours = hours['workingHours'];

          for (String day in _daysOrder) {
            if (loadedHours[day] != null) {
              _workingHours[day] = Map<String, dynamic>.from(loadedHours[day]);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load working hours: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveWorkingHours() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final data = {
        'workingHours': _workingHours,
      };

      await apiService.updateBusinessWorkingHours(widget.business.id, data);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Working hours saved successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save working hours: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectTime(String day, bool isOpenTime) async {
    final currentTime = isOpenTime
        ? _workingHours[day]!['openTime']
        : _workingHours[day]!['closeTime'];

    final timeParts = currentTime.split(':');
    final initialTime = TimeOfDay(
        hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    
    if (picked != null) {
      final timeString =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isOpenTime) {
          _workingHours[day]!['openTime'] = timeString;
        } else {
          _workingHours[day]!['closeTime'] = timeString;
        }
      });
    }
  }

  void _copyToAllDays(String sourceDay) {
    final sourceHours = _workingHours[sourceDay]!;
    setState(() {
      for (String day in _daysOrder) {
        if (day != sourceDay) {
          _workingHours[day] = Map<String, dynamic>.from(sourceHours);
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied ${_dayNames[sourceDay]} hours to all days'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _setCommonSchedule(String schedule) {
    Map<String, dynamic> hours;

    switch (schedule) {
      case 'regular':
        hours = {'isOpen': true, 'openTime': '09:00', 'closeTime': '17:00'};
        break;
      case 'restaurant':
        hours = {'isOpen': true, 'openTime': '11:00', 'closeTime': '23:00'};
        break;
      case 'retail':
        hours = {'isOpen': true, 'openTime': '10:00', 'closeTime': '22:00'};
        break;
      default:
        return;
    }

    setState(() {
      for (String day in _daysOrder) {
        _workingHours[day] = Map<String, dynamic>.from(hours);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied $schedule hours to all days'),
        duration: const Duration(seconds: 2),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundVariant,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.05),
              AppColors.secondary.withOpacity(0.03),
              AppColors.background,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern App Bar
              _buildModernAppBar(loc),

              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            // Quick Presets Section
                            _buildQuickPresetsSection(),

                            // Working Hours Cards
                            _buildWorkingHoursSection(),

                            // Save Button
                            _buildSaveButton(),

                            // Bottom spacing
                            SizedBox(height: GoldenRatio.spacing24),
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

  Widget _buildModernAppBar(AppLocalizations loc) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: GoldenRatio.spacing20,
        vertical: GoldenRatio.spacing16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.04),
            blurRadius: GoldenRatio.spacing12,
            offset: Offset(0, GoldenRatio.spacing4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: AppColors.primary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SizedBox(width: GoldenRatio.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.workingHoursSettings,
                  style: TypographySystem.headlineSmall.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Set your business hours',
                  style: TypographySystem.bodyMedium.copyWith(
                    color: AppColors.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: GoldenRatio.spacing8,
                  offset: Offset(0, GoldenRatio.spacing4),
                ),
              ],
            ),
            child: IconButton(
              icon: _isLoading
                  ? SizedBox(
                      width: GoldenRatio.spacing20,
                      height: GoldenRatio.spacing20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : Icon(Icons.save_rounded, color: AppColors.onPrimary),
              onPressed: _isLoading ? null : _saveWorkingHours,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(GoldenRatio.spacing24 + GoldenRatio.spacing8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.1),
              blurRadius: GoldenRatio.spacing20,
              offset: Offset(0, GoldenRatio.spacing8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            SizedBox(height: GoldenRatio.spacing16),
            Text(
              'Loading working hours...',
              style: TypographySystem.bodyLarge.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPresetsSection() {
    return Container(
      margin: EdgeInsets.all(GoldenRatio.spacing20),
      padding: EdgeInsets.all(GoldenRatio.spacing24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.04),
            blurRadius: GoldenRatio.spacing20,
            offset: Offset(0, GoldenRatio.spacing8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(GoldenRatio.spacing12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondary.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  color: AppColors.primary,
                  size: GoldenRatio.spacing20,
                ),
              ),
              SizedBox(width: GoldenRatio.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Presets',
                      style: TypographySystem.headlineSmall.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Apply common schedules to all days',
                      style: TypographySystem.bodyMedium.copyWith(
                        color: AppColors.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: GoldenRatio.spacing20),
          Wrap(
            spacing: GoldenRatio.spacing12,
            runSpacing: GoldenRatio.spacing12,
            children: [
              _buildPresetButton('9AM-5PM', 'regular'),
              _buildPresetButton('11AM-11PM', 'restaurant'),
              _buildPresetButton('10AM-10PM', 'retail'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(String label, String schedule) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: GoldenRatio.spacing8,
            offset: Offset(0, GoldenRatio.spacing4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _setCommonSchedule(schedule),
          borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: GoldenRatio.spacing20,
              vertical: GoldenRatio.spacing12,
            ),
            child: Text(
              label,
              style: TypographySystem.titleMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkingHoursSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: GoldenRatio.spacing20),
      child: Column(
        children: _daysOrder.map((day) => _buildModernDayCard(day)).toList(),
      ),
    );
  }

  Widget _buildModernDayCard(String day) {
    final dayData = _workingHours[day]!;
    
    return Container(
      margin: EdgeInsets.only(bottom: GoldenRatio.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
        border: Border.all(
          color: dayData['isOpen'] 
              ? AppColors.primary.withOpacity(0.2)
              : AppColors.onSurface.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.05),
            blurRadius: GoldenRatio.spacing16,
            offset: Offset(0, GoldenRatio.spacing4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(GoldenRatio.spacing20),
        child: Column(
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(GoldenRatio.spacing12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: dayData['isOpen']
                          ? [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.1)]
                          : [AppColors.onSurface.withOpacity(0.05), AppColors.onSurface.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
                  ),
                  child: Icon(
                    dayData['isOpen'] ? Icons.access_time_rounded : Icons.block_rounded,
                    color: dayData['isOpen'] ? AppColors.primary : AppColors.onSurface.withOpacity(0.5),
                    size: GoldenRatio.spacing20,
                  ),
                ),
                SizedBox(width: GoldenRatio.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dayNames[day]!,
                        style: TypographySystem.headlineSmall.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        dayData['isOpen']
                            ? '${dayData['openTime']} - ${dayData['closeTime']}'
                            : 'Closed',
                        style: TypographySystem.bodyMedium.copyWith(
                          color: dayData['isOpen']
                              ? AppColors.primary
                              : AppColors.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Switch
                Container(
                  decoration: BoxDecoration(
                    color: dayData['isOpen']
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
                  ),
                  child: Switch(
                    value: dayData['isOpen'],
                    onChanged: (value) {
                      setState(() {
                        _workingHours[day]!['isOpen'] = value;
                      });
                    },
                    activeColor: AppColors.primary,
                    inactiveThumbColor: AppColors.onSurface.withOpacity(0.4),
                    inactiveTrackColor: AppColors.onSurface.withOpacity(0.1),
                  ),
                ),
                SizedBox(width: GoldenRatio.spacing8),
                // Menu Button
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(GoldenRatio.radiusMd),
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.primary,
                      size: GoldenRatio.spacing20,
                    ),
                    onSelected: (value) {
                      if (value == 'copy') {
                        _copyToAllDays(day);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(Icons.copy_rounded,
                                size: GoldenRatio.spacing18,
                                color: AppColors.primary),
                            SizedBox(width: GoldenRatio.spacing8),
                            Text(
                              'Copy to all days',
                              style: TypographySystem.bodyMedium.copyWith(
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Time Selection Section (only if open)
            if (dayData['isOpen']) ...[
              SizedBox(height: GoldenRatio.spacing20),
              Container(
                padding: EdgeInsets.all(GoldenRatio.spacing16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Open Time
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectTime(day, true),
                        child: Container(
                          padding: EdgeInsets.all(GoldenRatio.spacing16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(GoldenRatio.radiusMd),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.1),
                                blurRadius: GoldenRatio.spacing8,
                                offset: Offset(0, GoldenRatio.spacing4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(GoldenRatio.spacing8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      GoldenRatio.radiusSm),
                                ),
                                child: Icon(
                                  Icons.schedule_rounded,
                                  size: GoldenRatio.spacing16,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: GoldenRatio.spacing12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Opens',
                                      style:
                                          TypographySystem.bodySmall.copyWith(
                                        color: AppColors.onSurface
                                            .withOpacity(0.6),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: GoldenRatio.spacing4),
                                    Text(
                                      dayData['openTime'],
                                      style:
                                          TypographySystem.titleMedium.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: GoldenRatio.spacing12),
                    // Close Time
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectTime(day, false),
                        child: Container(
                          padding: EdgeInsets.all(GoldenRatio.spacing16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(GoldenRatio.radiusMd),
                            border: Border.all(
                              color: AppColors.secondary.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary.withOpacity(0.1),
                                blurRadius: GoldenRatio.spacing8,
                                offset: Offset(0, GoldenRatio.spacing4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(GoldenRatio.spacing8),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      GoldenRatio.radiusSm),
                                ),
                                child: Icon(
                                  Icons.schedule_rounded,
                                  size: GoldenRatio.spacing16,
                                  color: AppColors.secondary,
                                ),
                              ),
                              SizedBox(width: GoldenRatio.spacing12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Closes',
                                      style:
                                          TypographySystem.bodySmall.copyWith(
                                        color: AppColors.onSurface
                                            .withOpacity(0.6),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: GoldenRatio.spacing4),
                                    Text(
                                      dayData['closeTime'],
                                      style:
                                          TypographySystem.titleMedium.copyWith(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(height: GoldenRatio.spacing16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(GoldenRatio.spacing16),
                decoration: BoxDecoration(
                  color: AppColors.onSurface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(GoldenRatio.radiusLg),
                  border: Border.all(
                    color: AppColors.onSurface.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.block_rounded,
                      color: AppColors.onSurface.withOpacity(0.4),
                      size: GoldenRatio.spacing20,
                    ),
                    SizedBox(width: GoldenRatio.spacing8),
                    Text(
                      'Closed',
                      style: TypographySystem.titleMedium.copyWith(
                        color: AppColors.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      margin: EdgeInsets.all(GoldenRatio.spacing20),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: GoldenRatio.spacing16,
            offset: Offset(0, GoldenRatio.spacing8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _saveWorkingHours,
          borderRadius: BorderRadius.circular(GoldenRatio.radiusXl),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: GoldenRatio.spacing16 + GoldenRatio.spacing4,
              horizontal: GoldenRatio.spacing24,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading) ...[
                  SizedBox(
                    width: GoldenRatio.spacing20,
                    height: GoldenRatio.spacing20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  ),
                  SizedBox(width: GoldenRatio.spacing12),
                ] else ...[
                  Icon(
                    Icons.save_rounded,
                    color: AppColors.onPrimary,
                    size: GoldenRatio.spacing20,
                  ),
                  SizedBox(width: GoldenRatio.spacing12),
                ],
                Text(
                  _isLoading ? 'Saving...' : 'Save Working Hours',
                  style: TypographySystem.titleMedium.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
