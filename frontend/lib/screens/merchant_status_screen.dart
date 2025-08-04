import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../../models/business.dart';
import '../../services/app_auth_service.dart';
import 'login_page.dart';

class MerchantStatusScreen extends StatelessWidget {
  final Business business;

  const MerchantStatusScreen({Key? key, required this.business})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    String statusMessage;
    String statusDescription;
    IconData statusIcon;
    Color statusColor;

    switch (business.status) {
      case 'pending':
      case 'pending_verification':
        statusMessage = loc.applicationPending;
        statusDescription = loc.applicationPendingDescription;
        statusIcon = Icons.hourglass_empty;
        statusColor = Colors.orange;
        break;
      case 'approved':
        statusMessage = loc.applicationApproved;
        statusDescription = loc.applicationApprovedDescription;
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusMessage = loc.applicationRejected;
        statusDescription = loc.applicationRejectedDescription;
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        break;
      case 'under_review':
        statusMessage = loc.underReview;
        statusDescription = loc.underReviewDescription;
        statusIcon = Icons.assignment;
        statusColor = Colors.blue;
        break;
      default:
        statusMessage = loc.statusUnknown;
        statusDescription = loc.statusUnknownDescription;
        statusIcon = Icons.help_outline;
        statusColor = Colors.grey;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.applicationStatus),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await AppAuthService.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => const LoginPage()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                statusIcon,
                size: 80,
                color: statusColor,
              ),
              SizedBox(height: 24),
              Text(
                statusMessage,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                statusDescription,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
