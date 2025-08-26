import 'package:flutter/material.dart';
import '../services/business_status_service.dart';

/// Widget that shows business online status with automatic updates
class BusinessOnlineStatusIndicator extends StatefulWidget {
  final String businessId;
  final Widget? child; // Optional child widget to wrap
  final bool showText; // Whether to show "Online" text
  final double size; // Size of the indicator
  final EdgeInsets? padding;

  const BusinessOnlineStatusIndicator({
    Key? key,
    required this.businessId,
    this.child,
    this.showText = false,
    this.size = 12.0,
    this.padding,
  }) : super(key: key);

  @override
  State<BusinessOnlineStatusIndicator> createState() =>
      _BusinessOnlineStatusIndicatorState();
}

class _BusinessOnlineStatusIndicatorState
    extends State<BusinessOnlineStatusIndicator> {
  bool _isOnline = false;
  bool _isLoading = true;
  final BusinessStatusService _statusService = BusinessStatusService();

  @override
  void initState() {
    super.initState();
    _checkBusinessStatus();
    // Set up periodic status checks
    _startStatusMonitoring();
  }

  void _startStatusMonitoring() {
    // Check status every 30 seconds
    Stream.periodic(const Duration(seconds: 30)).listen((_) {
      if (mounted) {
        _checkBusinessStatus();
      }
    });
  }

  Future<void> _checkBusinessStatus() async {
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
          _isOnline = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildContent(
        indicator: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      );
    }

    final indicator = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: _isOnline ? Colors.green : Colors.grey,
        shape: BoxShape.circle,
        boxShadow: _isOnline
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );

    return _buildContent(indicator: indicator);
  }

  Widget _buildContent({required Widget indicator}) {
    Widget content = indicator;

    if (widget.showText) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(width: 6),
          Text(
            _isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: _isOnline ? Colors.green : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    if (widget.child != null) {
      content = Stack(
        children: [
          widget.child!,
          Positioned(
            top: 4,
            right: 4,
            child: content,
          ),
        ],
      );
    }

    if (widget.padding != null) {
      content = Padding(
        padding: widget.padding!,
        child: content,
      );
    }

    return content;
  }
}

/// Widget for showing multiple businesses online status in a list
class BusinessListWithOnlineStatus extends StatefulWidget {
  final List<String> businessIds;
  final Widget Function(String businessId, bool isOnline) itemBuilder;

  const BusinessListWithOnlineStatus({
    Key? key,
    required this.businessIds,
    required this.itemBuilder,
  }) : super(key: key);

  @override
  State<BusinessListWithOnlineStatus> createState() =>
      _BusinessListWithOnlineStatusState();
}

class _BusinessListWithOnlineStatusState
    extends State<BusinessListWithOnlineStatus> {
  Map<String, bool> _statusMap = {};
  bool _isLoading = true;
  final BusinessStatusService _statusService = BusinessStatusService();

  @override
  void initState() {
    super.initState();
    _loadBusinessStatuses();
    _startStatusMonitoring();
  }

  void _startStatusMonitoring() {
    // Check status every 45 seconds for lists
    Stream.periodic(const Duration(seconds: 45)).listen((_) {
      if (mounted) {
        _loadBusinessStatuses();
      }
    });
  }

  Future<void> _loadBusinessStatuses() async {
    try {
      final statusMap =
          await _statusService.getMultipleBusinessesStatus(widget.businessIds);
      if (mounted) {
        setState(() {
          _statusMap = statusMap;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView.builder(
      itemCount: widget.businessIds.length,
      itemBuilder: (context, index) {
        final businessId = widget.businessIds[index];
        final isOnline = _statusMap[businessId] ?? false;
        return widget.itemBuilder(businessId, isOnline);
      },
    );
  }
}
