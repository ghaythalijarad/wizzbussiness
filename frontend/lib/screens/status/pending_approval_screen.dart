import 'package:flutter/material.dart';
import '../signin_screen.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status: Pending Review'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.hourglass_top, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                'Your Account is Pending Review',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Our team is currently reviewing your business information. This process usually takes 1-2 business days. We will notify you via email once the review is complete.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const SignInScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text('Go to Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
