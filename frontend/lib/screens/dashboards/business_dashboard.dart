import 'package:flutter/material.dart';
import '../../models/business.dart';
import '../../l10n/app_localizations.dart';
import '../orders_page.dart';
import '../items_management_page.dart';
import '../analytics_page.dart';
import '../discount_management_page.dart';
import '../profile_settings_page.dart';
import '../../models/order.dart';
import '../../models/order_item.dart';
import '../../widgets/top_app_bar.dart';

class BusinessDashboard extends StatefulWidget {
  final Business business;
  final void Function(Locale) onLanguageChanged;

  const BusinessDashboard({
    Key? key,
    required this.business,
    required this.onLanguageChanged,
  }) : super(key: key);

  @override
  _BusinessDashboardState createState() => _BusinessDashboardState();
}

class _BusinessDashboardState extends State<BusinessDashboard> {
  int _selectedIndex = 0;
  List<Order> _orders = [];
  bool _isOnline = true; // Business online/offline status

  @override
  void initState() {
    super.initState();
    _generateDemoOrders();
  }

  void _generateDemoOrders() {
    final now = DateTime.now();

    // Generate orders based on business type
    final demoOrders = <Order>[
      Order(
        id: 'ORD-001',
        customerId: 'CUST-001',
        customerName: _getCustomerName(0),
        customerPhone: '+965 1234 5678',
        deliveryAddress: _getDeliveryAddress(0),
        items: _getOrderItems(0),
        totalAmount: _calculateTotal(_getOrderItems(0)),
        createdAt: now.subtract(const Duration(minutes: 5)),
        status: OrderStatus.pending,
        notes: _getOrderNotes(0),
        estimatedPreparationTimeMinutes: 25,
      ),
      Order(
        id: 'ORD-002',
        customerId: 'CUST-002',
        customerName: _getCustomerName(1),
        customerPhone: '+965 2345 6789',
        deliveryAddress: _getDeliveryAddress(1),
        items: _getOrderItems(1),
        totalAmount: _calculateTotal(_getOrderItems(1)),
        createdAt: now.subtract(const Duration(minutes: 15)),
        status: OrderStatus.confirmed,
        notes: _getOrderNotes(1),
        estimatedPreparationTimeMinutes: 30,
      ),
      Order(
        id: 'ORD-003',
        customerId: 'CUST-003',
        customerName: _getCustomerName(2),
        customerPhone: '+965 3456 7890',
        deliveryAddress: _getDeliveryAddress(2),
        items: _getOrderItems(2),
        totalAmount: _calculateTotal(_getOrderItems(2)),
        createdAt: now.subtract(const Duration(hours: 1)),
        status: OrderStatus.ready,
        notes: null,
        estimatedPreparationTimeMinutes: 20,
      ),
    ];

    setState(() {
      _orders = demoOrders;
    });
  }

  String _getCustomerName(int index) {
    final businessType = widget.business.businessType;
    final names = <String>[];

    switch (businessType.name) {
      case 'restaurant':
        names.addAll(['Ahmed Al-Rashid', 'Sara Mohammed', 'Omar Khalid']);
        break;
      case 'pharmacy':
        names.addAll(['Fatima Hassan', 'Khalid Omar', 'Noor Al-Ahmad']);
        break;
      case 'store':
        names.addAll(['Mohammed Ali', 'Aisha Ibrahim', 'Youssef Ahmed']);
        break;
      case 'kitchen':
        names.addAll(['Maryam Saleh', 'Ali Hassan', 'Noura Saeed']);
        break;
      default:
        names.add('Customer ${index + 1}');
    }

    return names[index % names.length];
  }

  String _getDeliveryAddress(int index) {
    final addresses = [
      'Kuwait City, Block 5, Street 12, Building 25',
      'Salmiya, Block 10, Street 8, Building 15',
      'Hawally, Block 3, Street 7, Building 20',
    ];
    return addresses[index % addresses.length];
  }

  List<OrderItem> _getOrderItems(int index) {
    final businessType = widget.business.businessType;
    switch (businessType.name) {
      case 'restaurant':
        return _getRestaurantItems(index);
      case 'pharmacy':
        return _getPharmacyItems(index);
      case 'store':
        return _getStoreItems(index);
      case 'kitchen':
        return _getKitchenItems(index);
      default:
        return _getDefaultItems(index);
    }
  }

  List<OrderItem> _getRestaurantItems(int index) {
    final items = [
      [
        OrderItem(
            dishId: 'DISH-001',
            dishName: 'Margherita Pizza',
            quantity: 1,
            price: 8.500),
        OrderItem(
            dishId: 'DISH-002',
            dishName: 'Caesar Salad',
            quantity: 2,
            price: 4.250),
      ],
      [
        OrderItem(
            dishId: 'DISH-003',
            dishName: 'Grilled Chicken',
            quantity: 1,
            price: 12.000),
        OrderItem(
            dishId: 'DISH-004',
            dishName: 'French Fries',
            quantity: 1,
            price: 3.500),
      ],
      [
        OrderItem(
            dishId: 'DISH-005',
            dishName: 'Pasta Alfredo',
            quantity: 1,
            price: 9.750),
      ],
    ];
    return items[index % items.length];
  }

  List<OrderItem> _getPharmacyItems(int index) {
    final items = [
      [
        OrderItem(
            dishId: 'MED-001',
            dishName: 'Paracetamol 500mg',
            quantity: 2,
            price: 1.250),
        OrderItem(
            dishId: 'MED-002',
            dishName: 'Vitamin C Tablets',
            quantity: 1,
            price: 3.500),
      ],
      [
        OrderItem(
            dishId: 'MED-003',
            dishName: 'Cough Syrup',
            quantity: 1,
            price: 4.750),
        OrderItem(
            dishId: 'MED-004',
            dishName: 'Antiseptic Cream',
            quantity: 1,
            price: 2.250),
      ],
      [
        OrderItem(
            dishId: 'MED-005',
            dishName: 'Blood Pressure Monitor',
            quantity: 1,
            price: 25.000),
      ],
    ];
    return items[index % items.length];
  }

  List<OrderItem> _getStoreItems(int index) {
    final items = [
      [
        OrderItem(
            dishId: 'ITEM-001',
            dishName: 'Organic Apples (1kg)',
            quantity: 2,
            price: 2.500),
        OrderItem(
            dishId: 'ITEM-002',
            dishName: 'Fresh Milk (1L)',
            quantity: 1,
            price: 1.750),
      ],
      [
        OrderItem(
            dishId: 'ITEM-003',
            dishName: 'Whole Wheat Bread',
            quantity: 1,
            price: 0.750),
        OrderItem(
            dishId: 'ITEM-004',
            dishName: 'Free Range Eggs (12)',
            quantity: 1,
            price: 2.250),
      ],
      [
        OrderItem(
            dishId: 'ITEM-005',
            dishName: 'Olive Oil (500ml)',
            quantity: 1,
            price: 4.500),
      ],
    ];
    return items[index % items.length];
  }

  List<OrderItem> _getKitchenItems(int index) {
    final items = [
      [
        OrderItem(
            dishId: 'KITCHEN-001',
            dishName: 'Beef Burger',
            quantity: 2,
            price: 6.500),
        OrderItem(
            dishId: 'KITCHEN-002',
            dishName: 'Onion Rings',
            quantity: 1,
            price: 2.750),
      ],
      [
        OrderItem(
            dishId: 'KITCHEN-003',
            dishName: 'Chicken Wrap',
            quantity: 1,
            price: 5.250),
        OrderItem(
            dishId: 'KITCHEN-004',
            dishName: 'Soft Drink',
            quantity: 2,
            price: 1.000),
      ],
      [
        OrderItem(
            dishId: 'KITCHEN-005',
            dishName: 'Fish & Chips',
            quantity: 1,
            price: 8.750),
      ],
    ];
    return items[index % items.length];
  }

  List<OrderItem> _getDefaultItems(int index) {
    return [
      OrderItem(
          dishId: 'DEFAULT-001',
          dishName: 'Sample Item',
          quantity: 1,
          price: 5.000),
    ];
  }

  String? _getOrderNotes(int index) {
    final notes = [
      'Please ring the doorbell twice',
      'Customer has allergies - no nuts',
      null,
    ];
    return notes[index % notes.length];
  }

  double _calculateTotal(List<OrderItem> items) {
    return items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  void _addNewOrder() {
    final now = DateTime.now();
    final newOrderId =
        'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final orderIndex = _orders.length;

    final newOrder = Order(
      id: newOrderId,
      customerId: 'CUST-${orderIndex + 1}',
      customerName: _getCustomerName(orderIndex),
      customerPhone: '+965 ${1000 + orderIndex}0000',
      deliveryAddress: _getDeliveryAddress(orderIndex),
      items: _getOrderItems(orderIndex),
      totalAmount: _calculateTotal(_getOrderItems(orderIndex)),
      createdAt: now,
      status: OrderStatus.pending,
      notes: _getOrderNotes(orderIndex),
      estimatedPreparationTimeMinutes: 20 + (orderIndex % 3) * 5,
    );

    setState(() {
      _orders.insert(0, newOrder); // Add new order at the beginning
    });

    // Show notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New order #${newOrder.id} received!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _selectedIndex = 0; // Switch to orders tab
            });
          },
        ),
      ),
    );
  }

  // TopAppBar callback methods
  void _onToggleStatus(bool isOnline) {
    setState(() {
      _isOnline = isOnline;
    });

    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(isOnline ? loc.businessIsNowOnline : loc.businessIsNowOffline),
        backgroundColor: isOnline ? Colors.green : Colors.orange,
      ),
    );
  }

  void _onReturnOrder() {
    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.returnOrderFeature),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _onNavigate(int pageIndex) {
    setState(() {
      _selectedIndex = pageIndex;
    });
  }

  Widget _buildDashboardBody() {
    switch (_selectedIndex) {
      case 0:
        return OrdersPage(
          orders: _orders,
          onOrderUpdated: (orderId, status) {
            // Handle order status updates
            final orderIndex =
                _orders.indexWhere((order) => order.id == orderId);
            if (orderIndex != -1) {
              setState(() {
                _orders[orderIndex] =
                    _orders[orderIndex].copyWith(status: status);
              });
            }
          },
        );
      case 1:
        return ItemsManagementPage(
          business: widget.business,
          orders: _orders,
        );
      case 2:
        return AnalyticsPage(
          business: widget.business,
          orders: _orders,
        );
      case 3:
        return DiscountManagementPage(
          business: widget.business,
          orders: _orders,
        );
      case 4:
        return ProfileSettingsPage(
          business: widget.business,
          orders: _orders,
          onLanguageChanged: widget.onLanguageChanged,
        );
      default:
        return const Center(child: Text('Error'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: TopAppBar(
        title: widget.business.name,
        isOnline: _isOnline,
        onToggleStatus: _onToggleStatus,
        onReturnOrder: _onReturnOrder,
        onNavigate: _onNavigate,
      ),
      body: _buildDashboardBody(),
      floatingActionButton: _selectedIndex == 0 // Only show on orders page
          ? FloatingActionButton(
              onPressed: _addNewOrder,
              backgroundColor: Colors.green,
              tooltip: 'Simulate New Order',
              child: const Icon(Icons.add_shopping_cart, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_alt),
            label: loc.orders,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.store),
            label: loc.items,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.analytics),
            label: loc.analytics,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.discount),
            label: loc.discounts,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: loc.settings,
          ),
        ],
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
