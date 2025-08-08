import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/delivery_address.dart';
import '../widgets/order_card.dart';
import '../utils/responsive_helper.dart';

class OrdersPreviewPage extends StatefulWidget {
  const OrdersPreviewPage({Key? key}) : super(key: key);

  @override
  _OrdersPreviewPageState createState() => _OrdersPreviewPageState();
}

class _OrdersPreviewPageState extends State<OrdersPreviewPage> {
  String _selectedFilter = 'pending';

  // Mock data for preview
  late List<Order> _mockOrders;

  @override
  void initState() {
    super.initState();
    _generateMockOrders();
  }

  void _generateMockOrders() {
    final now = DateTime.now();

    _mockOrders = [
      // Pending orders
      Order(
        id: 'ORD-001',
        customerId: 'CUST-001',
        customerName: 'أحمد محمد',
        customerPhone: '+964 770 123 4567',
        deliveryAddress: DeliveryAddress(
          street: 'شارع الجامعة',
          city: 'بغداد، العراق',
        ),
        items: [
          OrderItem(
            dishId: 'DISH-001',
            dishName: 'برياني لحم',
            price: 25.0,
            quantity: 2,
            notes: 'بدون فلفل حار',
          ),
          OrderItem(
            dishId: 'DISH-002',
            dishName: 'سلطة خضراء',
            price: 8.0,
            quantity: 1,
          ),
        ],
        totalAmount: 58.0,
        createdAt: now.subtract(Duration(minutes: 5)),
        status: OrderStatus.pending,
        notes: 'يرجى التوصيل بسرعة',
        estimatedPreparationTimeMinutes: 30,
      ),
      Order(
        id: 'ORD-002',
        customerId: 'CUST-002',
        customerName: 'فاطمة علي',
        customerPhone: '+964 771 987 6543',
        deliveryAddress: DeliveryAddress(
          street: 'الكرادة الداخلية',
          city: 'بغداد، العراق',
        ),
        items: [
          OrderItem(
            dishId: 'DISH-003',
            dishName: 'شاورما دجاج',
            price: 12.0,
            quantity: 3,
          ),
          OrderItem(
            dishId: 'DISH-004',
            dishName: 'عصير برتقال',
            price: 5.0,
            quantity: 2,
          ),
        ],
        totalAmount: 46.0,
        createdAt: now.subtract(Duration(minutes: 12)),
        status: OrderStatus.pending,
        estimatedPreparationTimeMinutes: 20,
      ),

      // Confirmed orders
      Order(
        id: 'ORD-003',
        customerId: 'CUST-003',
        customerName: 'محمد حسن',
        customerPhone: '+964 772 456 7890',
        deliveryAddress: DeliveryAddress(
          street: 'المنصور',
          city: 'بغداد، العراق',
        ),
        items: [
          OrderItem(
            dishId: 'DISH-005',
            dishName: 'كباب مشوي',
            price: 20.0,
            quantity: 1,
          ),
          OrderItem(
            dishId: 'DISH-006',
            dishName: 'أرز أبيض',
            price: 6.0,
            quantity: 2,
          ),
        ],
        totalAmount: 32.0,
        createdAt: now.subtract(Duration(minutes: 25)),
        status: OrderStatus.confirmed,
        estimatedPreparationTimeMinutes: 25,
      ),

      // Ready orders
      Order(
        id: 'ORD-004',
        customerId: 'CUST-004',
        customerName: 'سارة أحمد',
        customerPhone: '+964 773 321 0987',
        deliveryAddress: DeliveryAddress(
          street: 'الجادرية',
          city: 'بغداد، العراق',
        ),
        items: [
          OrderItem(
            dishId: 'DISH-007',
            dishName: 'بيتزا مارجريتا',
            price: 18.0,
            quantity: 1,
          ),
          OrderItem(
            dishId: 'DISH-008',
            dishName: 'كولا',
            price: 3.0,
            quantity: 2,
          ),
        ],
        totalAmount: 24.0,
        createdAt: now.subtract(Duration(hours: 1)),
        status: OrderStatus.ready,
        estimatedPreparationTimeMinutes: 15,
      ),

      // Picked up orders
      Order(
        id: 'ORD-005',
        customerId: 'CUST-005',
        customerName: 'يوسف علي',
        customerPhone: '+964 774 654 3210',
        deliveryAddress: DeliveryAddress(
          street: 'الزعفرانية',
          city: 'بغداد، العراق',
        ),
        items: [
          OrderItem(
            dishId: 'DISH-009',
            dishName: 'دولمة',
            price: 15.0,
            quantity: 1,
          ),
          OrderItem(
            dishId: 'DISH-010',
            dishName: 'لبن',
            price: 2.0,
            quantity: 3,
          ),
        ],
        totalAmount: 21.0,
        createdAt: now.subtract(Duration(hours: 2)),
        status: OrderStatus.delivered,
        estimatedPreparationTimeMinutes: 20,
      ),

      // Cancelled orders
      Order(
        id: 'ORD-006',
        customerId: 'CUST-006',
        customerName: 'ليلى محمود',
        customerPhone: '+964 775 123 9876',
        deliveryAddress: DeliveryAddress(
          street: 'الدورة',
          city: 'بغداد، العراق',
        ),
        items: [
          OrderItem(
            dishId: 'DISH-011',
            dishName: 'مندي لحم',
            price: 30.0,
            quantity: 1,
          ),
        ],
        totalAmount: 30.0,
        createdAt: now.subtract(Duration(hours: 3)),
        status: OrderStatus.cancelled,
        notes: 'ألغي العميل الطلب',
        estimatedPreparationTimeMinutes: 45,
      ),
    ];
  }

  void _onOrderUpdated(String orderId, OrderStatus newStatus) {
    setState(() {
      final orderIndex = _mockOrders.indexWhere((order) => order.id == orderId);
      if (orderIndex != -1) {
        _mockOrders[orderIndex].status = newStatus;
      }
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('تم تحديث حالة الطلب إلى ${_getStatusDisplayName(newStatus)}'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _getStatusDisplayName(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'الطلبات الجديدة';
      case OrderStatus.confirmed:
        return 'مؤكدة';
      case OrderStatus.preparing:
        return 'قيد التحضير';
      case OrderStatus.ready:
        return 'جاهزة';
      case OrderStatus.onTheWay:
        return 'في الطريق';
      case OrderStatus.delivered:
        return 'مكتملة';
      case OrderStatus.cancelled:
        return 'ملغية';
      case OrderStatus.returned:
        return 'مرتجعة';
      case OrderStatus.expired:
        return 'منتهي الصلاحية';
    }
  }

  OrderStatus? _getStatusFromString(String value) {
    switch (value) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'on_the_way':
        return OrderStatus.onTheWay;
      case 'delivered':
      case 'pickedUp':
        return OrderStatus.delivered;
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
    List<Order> filteredOrders = _mockOrders;
    final filterStatus = _getStatusFromString(_selectedFilter);
    if (filterStatus != null) {
      filteredOrders =
          _mockOrders.where((o) => o.status == filterStatus).toList();
    }

    // Sort orders - pending orders by remaining time, others by creation time
    if (_selectedFilter == 'pending') {
      filteredOrders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
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
              textDirection:
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Wrap(
                  alignment: WrapAlignment.start,
                  runAlignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildFilterChip('الطلبات الجديدة', 'pending'),
                    _buildFilterChip('مؤكدة', 'confirmed'),
                    _buildFilterChip('جاهزة', 'ready'),
                    _buildFilterChip('مكتملة', 'pickedUp'),
                    _buildFilterChip('ملغية', 'cancelled'),
                    _buildFilterChip('مرتجعة', 'returned'),
                  ],
                ),
              ),
            ),
          ),

          // Orders list
          Expanded(
            child: filteredOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد طلبات في "${_getFilterDisplayName(_selectedFilter)}"',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ResponsiveHelper.isTablet(context) ||
                        ResponsiveHelper.isDesktop(context)
                    ? _buildGridLayout(filteredOrders)
                    : _buildListLayout(filteredOrders),
          ),
        ],
      ),
    );
  }

  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case 'pending':
        return 'الطلبات الجديدة';
      case 'confirmed':
        return 'المؤكدة';
      case 'ready':
        return 'الجاهزة';
      case 'pickedUp':
        return 'المكتملة';
      case 'cancelled':
        return 'الملغية';
      case 'returned':
        return 'المرتجعة';
      default:
        return filter;
    }
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    final count = _mockOrders
        .where((order) =>
            _getStatusFromString(value) == null ||
            order.status == _getStatusFromString(value))
        .length;

    // Define the custom blue color #00C1E8 for fill and the pink color #C6007E for borders
    const customBlueColor = Color(0xFF00C1E8);
    const customPinkColor = Color(0xFFC6007E);

    // Responsive sizing for chips - longer and little higher
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveHelper.isMobile(context);

    // Increased horizontal padding for longer chips
    double horizontalPadding;
    double verticalPadding; // Increased vertical padding for higher chips
    double fontSize;

    if (screenWidth < 400) {
      // Very small mobile screens
      horizontalPadding = 12; // Increased from 8 for longer chips
      verticalPadding = 8; // Increased from 4 for higher chips
      fontSize = 13; // Increased from 11 for better visibility
    } else if (isMobile) {
      // Regular mobile screens
      horizontalPadding = 16; // Increased from 10 for longer chips
      verticalPadding = 8; // Increased from 4 for higher chips
      fontSize = 14; // Increased from 12 for better visibility
    } else {
      // Desktop/tablet
      horizontalPadding = 20; // Increased from 12 for longer chips
      verticalPadding = 10; // Increased from 6 for higher chips
      fontSize = 15; // Increased from 13 for better visibility
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        elevation: isSelected ? 2 : 0.5,
        borderRadius: BorderRadius.circular(
            8), // Reduced from 16 to 8 for less round corners
        color: isSelected
            ? customBlueColor
            : const Color(0xFF001133).withOpacity(0.05),
        shadowColor: isSelected
            ? customBlueColor.withOpacity(0.3)
            : const Color(0xFF001133).withOpacity(0.1),
        child: InkWell(
          onTap: () => setState(() => _selectedFilter = value),
          borderRadius:
              BorderRadius.circular(8), // Match the container border radius
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: verticalPadding),
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(8), // Reduced corners here too
              border: Border.all(
                color: isSelected
                    ? customPinkColor
                    : customPinkColor.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : customBlueColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: fontSize,
                    letterSpacing: 0.1, // Slightly reduced letter spacing
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis, // Handle text overflow
                ),
                if (count > 0) ...[
                  SizedBox(width: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.3)
                          : customBlueColor,
                      borderRadius:
                          BorderRadius.circular(8), // Reduced from 10 to 8
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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
          onOrderUpdated: _onOrderUpdated,
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
          onOrderUpdated: _onOrderUpdated,
        );
      },
    );
  }
}
