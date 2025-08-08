import 'package:flutter/material.dart';
import '../../models/business.dart';
import '../../services/admin_service.dart';
import '../../services/app_auth_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<List<Business>> _pendingBusinesses;
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  void _initializeDashboard() async {
    try {
      final token = await AppAuthService.getAccessToken();
      if (token != null) {
        _pendingBusinesses = _adminService.getPendingBusinesses(token);
      }
    } catch (e) {
      // Handle error
    }
  }

  void _approveMerchant(String businessId) async {
    try {
      final token = await AppAuthService.getAccessToken();
      if (token != null) {
        await _adminService.approveMerchant(token, businessId);
        setState(() {
          _pendingBusinesses = _adminService.getPendingBusinesses(token);
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Merchant approved successfully')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error approving merchant: $e')));
    }
  }

  void _rejectMerchant(String businessId) async {
    try {
      final token = await AppAuthService.getAccessToken();
      if (token != null) {
        await _adminService.rejectMerchant(token, businessId);
        setState(() {
          _pendingBusinesses = _adminService.getPendingBusinesses(token);
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Merchant rejected successfully')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error rejecting merchant: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: FutureBuilder<List<Business>>(
        future: _pendingBusinesses,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No pending merchants found.'));
          } else {
            final businesses = snapshot.data!;
            return ListView.builder(
              itemCount: businesses.length,
              itemBuilder: (context, index) {
                final business = businesses[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(business.name),
                    subtitle: Text('Status: ${business.status}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () => _approveMerchant(business.id),
                          child: Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _rejectMerchant(business.id),
                          child: Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
