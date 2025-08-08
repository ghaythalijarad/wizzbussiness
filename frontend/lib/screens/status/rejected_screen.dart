import 'package:flutter/material.dart';
import '../signup_screen.dart';

class RejectedScreen extends StatelessWidget {
  final String? reason;

  const RejectedScreen({Key? key, this.reason}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status: Application Rejected'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.cancel, size: 80, color: Colors.red),
              const SizedBox(height: 24),
              const Text(
                'Your Application Was Rejected',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                reason ??
                    'Unfortunately, we were unable to approve your business account at this time. Please contact support for more information.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const SignUpScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text('Start Over'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
