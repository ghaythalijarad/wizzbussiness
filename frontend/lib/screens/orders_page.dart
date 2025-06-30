import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/order.dart';
import '../services/order_timer_service.dart';
// import '../services/order_simulation_service.dart';
import '../widgets/order_card.dart';
import '../utils/responsive_helper.dart';

class OrdersPage extends StatefulWidget {
  final List<Order> orders;
  final Function(String, OrderStatus) onOrderUpdated;
  final String? businessId;
  final Function()? onOrdersRefresh;

  const OrdersPage({
    Key? key,
    required this.orders,
    required this.onOrderUpdated,
    this.businessId,
    this.onOrdersRefresh,
  }) : super(key: key);

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String _selectedFilter = 'pending';
  // final OrderSimulationService _simulationService = OrderSimulationService();

  OrderStatus? _getStatusFromString(String value) {
    switch (value) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'ready':
        return OrderStatus.ready;
      case 'pickedUp':
        return OrderStatus.pickedUp;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'returned':
        return OrderStatus.returned;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    List<Order> filteredOrders = widget.orders;
    final filterStatus = _getStatusFromString(_selectedFilter);
    if (filterStatus != null) {
      filteredOrders =
          widget.orders.where((o) => o.status == filterStatus).toList();
    }
    if (_selectedFilter == 'pending') {
      filteredOrders.sort((a, b) {
        final ra = OrderTimerService.getRemainingSeconds(a.id);
        final rb = OrderTimerService.getRemainingSeconds(b.id);
        return ra.compareTo(rb);
      });
    } else {
      filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return Scaffold(
      body: Column(
        children: [
          // Filter bar
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Directionality(
              textDirection: Localizations.localeOf(context).languageCode == 'ar' 
                  ? TextDirection.rtl 
                  : TextDirection.ltr,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip(loc.pending, 'pending'),
                  const SizedBox(width: 6),
                  _buildFilterChip(loc.confirmed, 'confirmed'),
                  const SizedBox(width: 6),
                  _buildFilterChip(loc.orderReady, 'ready'),
                  const SizedBox(width: 6),
                  _buildFilterChip(loc.pickedUp, 'pickedUp'),
                  const SizedBox(width: 6),
                  _buildFilterChip(loc.cancelled, 'cancelled'),
                  const SizedBox(width: 6),
                  _buildFilterChip(loc.orderReturned, 'returned'),
                  // Simulation functionality temporarily disabled
                  // if (widget.businessId != null) ...[
                  //   const SizedBox(width: 16),
                  //   ElevatedButton(
                  //     onPressed: () async {
                  //       if (_isSimulating) {
                  //         setState(() {
                  //           _isSimulating = false;
                  //         });
                  //       } else {
                  //         await _simulationService.createSimulatedOrder(widget.businessId!);
                  //         setState(() {
                  //           _isSimulating = true;
                  //         });
                  //       }
                  //     },
                  //     child: Text(_isSimulating
                  //         ? loc.stopSimulation
                  //         : loc.startSimulation),
                  //   ),
                  //   const SizedBox(width: 16),
                  //   ElevatedButton(
                  //     onPressed: () {
                  //       if (widget.businessId != null) {
                  //         _simulationService
                  //             .createSimulatedOrder(widget.businessId!);
                  //       }
                  //     },
                  //     child: Text(loc.simulateNewOrder),
                  //   ),
                  // ],
                ],
              ),
            ),
            ),
          ),
          // Orders list
          Expanded(
            child: filteredOrders.isEmpty
                ? Center(
                    child: Text(
                      loc.noOrdersFoundFor(_selectedFilter),
                    ),
                  )
                : ResponsiveHelper.isTablet(context) ||
                        ResponsiveHelper.isDesktop(context)
                    ? _buildGridLayout(filteredOrders)
                    : _buildListLayout(filteredOrders),
          ),
        ],
      ),
      floatingActionButton:
          null, // widget.businessId != null ? _buildSimulationFAB(loc) : null,
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
    );
  }

  Widget _buildListLayout(List<Order> orders) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(ResponsiveHelper.getResponsivePadding(context)),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderCard(
          order: order,
          onOrderUpdated: widget.onOrderUpdated,
        );
      },
    );
  }

  Widget _buildGridLayout(List<Order> orders) {
    final crossAxisCount = ResponsiveHelper.getGridCrossAxisCount(context);
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(ResponsiveHelper.getResponsivePadding(context)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: ResponsiveHelper.isDesktop(context) ? 1.2 : 0.85,
      ),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderCard(
          order: order,
          onOrderUpdated: widget.onOrderUpdated,
        );
      },
    );
  }

  // Simulation functionality temporarily disabled
  /*
  Future<void> _simulateSingleOrder() async {
    if (widget.businessId == null) return;
    
    setState(() => _isSimulating = true);
    
    try {
      await _simulationService.createSimulatedOrder(widget.businessId!);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Test order created successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Refresh orders if callback provided
        widget.onOrdersRefresh?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to create order: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSimulating = false);
      }
    }
  }

  Future<void> _simulateMultipleOrders() async {
    if (widget.businessId == null) return;
    
    setState(() => _isSimulating = true);
    
    try {
      // Create 3 simulated orders
      for (int i = 0; i < 3; i++) {
        await _simulationService.createSimulatedOrder(widget.businessId!);
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('3 test orders created successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Refresh orders if callback provided
        widget.onOrdersRefresh?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('${AppLocalizations.of(context)!.failedToCreateOrders}: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSimulating = false);
      }
    }
  }
  */
}
