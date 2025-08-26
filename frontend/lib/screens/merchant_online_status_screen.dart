import 'package:flutter/material.dart';
import '../services/business_status_service.dart';
import '../services/realtime_order_service.dart';

/// Screen for merchants to control their online status
class MerchantOnlineStatusScreen extends StatefulWidget {
  final String businessId;

  const MerchantOnlineStatusScreen({
    Key? key,
    required this.businessId,
  }) : super(key: key);

  @override
  State<MerchantOnlineStatusScreen> createState() =>
      _MerchantOnlineStatusScreenState();
}

class _MerchantOnlineStatusScreenState
    extends State<MerchantOnlineStatusScreen> {
  bool _isOnline = false;
  bool _isLoading = true;
  bool _isToggling = false;
  final BusinessStatusService _statusService = BusinessStatusService();
  final RealtimeOrderService _realtimeService = RealtimeOrderService();

  @override
  void initState() {
    super.initState();
    _checkCurrentStatus();
    _listenToConnectionStatus();
  }

  void _listenToConnectionStatus() {
    _realtimeService.connectionStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isOnline = isConnected;
        });
      }
    });
  }

  Future<void> _checkCurrentStatus() async {
    try {
      final isOnline = await _statusService.isBusinessOnline(widget.businessId);
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleOnlineStatus() async {
    if (_isToggling) return;

    setState(() {
      _isToggling = true;
    });

    try {
      if (_isOnline) {
        // Go offline - disconnect WebSocket
        await _realtimeService.disconnect();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔴 You are now offline'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // Go online - connect WebSocket
        await _realtimeService.initialize(widget.businessId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🟢 You are now online and ready to receive orders'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Check status again after a brief delay
      await Future.delayed(const Duration(seconds: 1));
      await _checkCurrentStatus();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to change status: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isToggling = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Status'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status Indicator
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _isLoading
                    ? Colors.grey.shade300
                    : (_isOnline
                        ? Colors.green.shade100
                        : Colors.orange.shade100),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isLoading
                      ? Colors.grey
                      : (_isOnline ? Colors.green : Colors.orange),
                  width: 4,
                ),
              ),
              child: Center(
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Icon(
                        _isOnline ? Icons.wifi : Icons.wifi_off,
                        size: 48,
                        color: _isOnline ? Colors.green : Colors.orange,
                      ),
              ),
            ),

            const SizedBox(height: 32),

            // Status Text
            Text(
              _isLoading
                  ? 'Checking status...'
                  : (_isOnline ? 'You are ONLINE' : 'You are OFFLINE'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isLoading
                    ? Colors.grey
                    : (_isOnline ? Colors.green : Colors.orange),
              ),
            ),

            const SizedBox(height: 16),

            // Status Description
            Text(
              _isLoading
                  ? 'Please wait...'
                  : (_isOnline
                      ? 'Customers can see your business and place orders'
                      : 'Customers cannot see your business or place orders'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 48),

            // Toggle Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed:
                    _isLoading || _isToggling ? null : _toggleOnlineStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isOnline ? Colors.orange : Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isToggling
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('Updating...'),
                        ],
                      )
                    : Text(
                        _isOnline ? 'Go Offline' : 'Go Online',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'How it works',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• When online, customers can find your business and place orders\n'
                    '• When offline, your business is hidden from customers\n'
                    '• You will receive real-time notifications when online\n'
                    '• Status automatically updates based on app connection',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
