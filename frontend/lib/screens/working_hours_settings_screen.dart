import 'package:flutter/material.dart';
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
          content: Text('Working hours saved successfully'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Working Hours Settings'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMsg != null
              ? Center(child: Text(errorMsg!))
              : ListView.builder(
                  itemCount: openingHours.keys.length,
                  itemBuilder: (context, index) {
                    String day = openingHours.keys.elementAt(index);
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              day,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Opening: ${openingHours[day]?.format(context) ?? 'Not set'}'),
                                ElevatedButton(
                                  onPressed: () => _selectTime(context, day, true),
                                  child: Text('Set Opening'),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Closing: ${closingHours[day]?.format(context) ?? 'Not set'}'),
                                ElevatedButton(
                                  onPressed: () => _selectTime(context, day, false),
                                  child: Text('Set Closing'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: isLoading ? null : _saveWorkingHours,
          child: Text('Save Settings'),
        ),
      ),
    );
  }
}
