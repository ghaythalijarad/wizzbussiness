import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/business.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';

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
  bool _is24Hours = false;

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
          _is24Hours = hours['is24Hours'] ?? false;

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
            backgroundColor: Colors.orange,
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
        'is24Hours': _is24Hours,
      };

      await apiService.updateBusinessWorkingHours(widget.business.id, data);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Working hours saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save working hours: $e'),
            backgroundColor: Colors.red,
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
        if (day != 'sunday') {
          _workingHours[day] = Map<String, dynamic>.from(hours);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.workingHoursSettings),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveWorkingHours,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Quick Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule,
                              color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Quick Setup',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 24 Hours Toggle
                      SwitchListTile(
                        title: const Text('Open 24 Hours'),
                        subtitle: const Text('Business is always open'),
                        value: _is24Hours,
                        onChanged: (value) {
                          setState(() {
                            _is24Hours = value;
                          });
                        },
                      ),

                      if (!_is24Hours) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: () => _setCommonSchedule('regular'),
                              child: const Text('9AM-5PM'),
                            ),
                            OutlinedButton(
                              onPressed: () => _setCommonSchedule('restaurant'),
                              child: const Text('11AM-11PM'),
                            ),
                            OutlinedButton(
                              onPressed: () => _setCommonSchedule('retail'),
                              child: const Text('10AM-10PM'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Working Hours List
                if (!_is24Hours)
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _daysOrder.length,
                      itemBuilder: (context, index) {
                        final day = _daysOrder[index];
                        final dayData = _workingHours[day]!;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _dayNames[day]!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Switch(
                                      value: dayData['isOpen'],
                                      onChanged: (value) {
                                        setState(() {
                                          _workingHours[day]!['isOpen'] = value;
                                        });
                                      },
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert),
                                      onSelected: (value) {
                                        if (value == 'copy') {
                                          _copyToAllDays(day);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'copy',
                                          child: Row(
                                            children: [
                                              Icon(Icons.copy),
                                              SizedBox(width: 8),
                                              Text('Copy to all days'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                
                                if (dayData['isOpen']) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _selectTime(day, true),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Theme.of(context)
                                                      .primaryColor
                                                      .withOpacity(0.3)),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.schedule,
                                                    size: 20),
                                                const SizedBox(width: 8),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Opens',
                                                      style: TextStyle(
                                                          fontSize: 12),
                                                    ),
                                                    Text(
                                                      dayData['openTime'],
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _selectTime(day, false),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Theme.of(context)
                                                      .primaryColor
                                                      .withOpacity(0.3)),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.schedule,
                                                    size: 20),
                                                const SizedBox(width: 8),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Closes',
                                                      style: TextStyle(
                                                          fontSize: 12),
                                                    ),
                                                    Text(
                                                      dayData['closeTime'],
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Closed',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Save Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveWorkingHours,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Working Hours'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
