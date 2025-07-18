import 'package:flutter/material.dart';

class WorkingHoursSettingsScreen extends StatefulWidget {
  @override
  _WorkingHoursSettingsScreenState createState() =>
      _WorkingHoursSettingsScreenState();
}

class _WorkingHoursSettingsScreenState
    extends State<WorkingHoursSettingsScreen> {
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

  Future<void> _selectTime(
      BuildContext context, String day, bool isOpening) async {
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
      body: ListView.builder(
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
                      Text(
                          'Opening: ${openingHours[day]?.format(context) ?? 'Not set'}'),
                      ElevatedButton(
                        onPressed: () => _selectTime(context, day, true),
                        child: Text('Set Opening'),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          'Closing: ${closingHours[day]?.format(context) ?? 'Not set'}'),
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
          onPressed: () {
            // Save the working hours to the database or API
          },
          child: Text('Save Settings'),
        ),
      ),
    );
  }
}
