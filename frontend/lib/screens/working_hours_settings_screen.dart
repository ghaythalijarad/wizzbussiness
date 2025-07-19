import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../models/business.dart';

class WorkingHoursSettingsScreen extends StatefulWidget {
  final Business? business;
  const WorkingHoursSettingsScreen({Key? key, this.business}) : super(key: key);
  @override
  _WorkingHoursSettingsScreenState createState() => _WorkingHoursSettingsScreenState();
}

class _WorkingHoursSettingsScreenState extends State<WorkingHoursSettingsScreen> {
  final Map<String, TimeOfDay?> openingHours = {
    'Monday': null,
    'Tuesday': null,
    'Wednesday': null,
    'Thursday': null,
    'Friday': null,
    'Saturday': null,
    'Sunday': null,
  };
  final Map<String, TimeOfDay?> closingHours = {
    'Monday': null,
    'Tuesday': null,
    'Wednesday': null,
    'Thursday': null,
    'Friday': null,
    'Saturday': null,
    'Sunday': null,
  };
  bool isLoading = false;
  String? errorMsg;

  // Helper method to get localized day name
  String getLocalizedDayName(String englishDay) {
    final l10n = AppLocalizations.of(context)!;
    switch (englishDay) {
      case 'Monday':
        return l10n.monday;
      case 'Tuesday':
        return l10n.tuesday;
      case 'Wednesday':
        return l10n.wednesday;
      case 'Thursday':
        return l10n.thursday;
      case 'Friday':
        return l10n.friday;
      case 'Saturday':
        return l10n.saturday;
      case 'Sunday':
        return l10n.sunday;
      default:
        return englishDay;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadWorkingHours();
  }

  Future<void> _loadWorkingHours() async {
    if (widget.business == null) return;
    setState(() { isLoading = true; errorMsg = null; });
    try {
      final api = ApiService();
      final result = await api.getBusinessWorkingHours(widget.business!.id);
      if (result['success'] == true && result['workingHours'] != null) {
        final wh = result['workingHours'] as Map<String, dynamic>;
        wh.forEach((day, hours) {
          if (hours['opening'] != null) {
            final opening = _parseTimeOfDay(hours['opening']);
            if (opening != null) openingHours[day] = opening;
          }
          if (hours['closing'] != null) {
            final closing = _parseTimeOfDay(hours['closing']);
            if (closing != null) closingHours[day] = closing;
          }
        });
      }
    } catch (e) {
      errorMsg = 'Failed to load working hours';
    }
    setState(() { isLoading = false; });
  }

  TimeOfDay? _parseTimeOfDay(dynamic value) {
    if (value is String && value.contains(':')) {
      final parts = value.split(':');
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    return null;
  }

  Future<void> _saveWorkingHours() async {
    if (widget.business == null) {
      print('❌ No business object provided');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No business information available')));
      return;
    }
    
    print('💾 Saving working hours for business: ${widget.business!.id}');
    setState(() { isLoading = true; errorMsg = null; });
    
    final api = ApiService();
    final Map<String, dynamic> wh = {};
    
    openingHours.forEach((day, open) {
      wh[day] = {
        'opening': open != null ? '${open.hour.toString().padLeft(2, '0')}:${open.minute.toString().padLeft(2, '0')}' : null,
        'closing': closingHours[day] != null ? '${closingHours[day]!.hour.toString().padLeft(2, '0')}:${closingHours[day]!.minute.toString().padLeft(2, '0')}' : null,
      };
    });
    
    print('📊 Working hours data to save: $wh');
    
    try {
      final result = await api.updateBusinessWorkingHours(widget.business!.id, wh);
      print('✅ API response: $result');
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.workingHoursSaved),
          backgroundColor: Colors.green,
        ));
      } else {
        errorMsg = 'Failed to save working hours: ${result['message'] ?? 'Unknown error'}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMsg!),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      print('❌ Error saving working hours: $e');
      errorMsg = 'Failed to save working hours: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ));
    }
    setState(() { isLoading = false; });
  }

  Future<void> _selectTime(BuildContext context, String day, bool isOpening) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isOpening) {
          openingHours[day] = picked;
        } else {
          closingHours[day] = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.workingHoursSettings),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMsg != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(errorMsg!, style: TextStyle(color: Colors.red)),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadWorkingHours,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: openingHours.keys.length,
                        itemBuilder: (context, index) {
                          String day = openingHours.keys.elementAt(index);
                          String localizedDay = getLocalizedDayName(day);
                          
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    localizedDay,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.openingTime,
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              openingHours[day]?.format(context) ?? l10n.notSet,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: openingHours[day] != null 
                                                    ? Colors.black87 
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () => _selectTime(context, day, true),
                                        icon: Icon(Icons.access_time, size: 18),
                                        label: Text(l10n.setOpeningTime),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).primaryColor,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.closingTime,
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              closingHours[day]?.format(context) ?? l10n.notSet,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: closingHours[day] != null 
                                                    ? Colors.black87 
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () => _selectTime(context, day, false),
                                        icon: Icon(Icons.access_time, size: 18),
                                        label: Text(l10n.setClosingTime),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).primaryColor,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : _saveWorkingHours,
                          icon: Icon(Icons.save, size: 20),
                          label: Text(
                            l10n.saveSettings,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
