import 'package:flutter/material.dart';

class OtherSettingsPage extends StatelessWidget {
  final TextEditingController _gpsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Other Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GPS Point',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _gpsController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter GPS location',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final gpsPoint = _gpsController.text;
                if (gpsPoint.isNotEmpty) {
                  // Save GPS point logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('GPS Point saved successfully!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid GPS Point.')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
