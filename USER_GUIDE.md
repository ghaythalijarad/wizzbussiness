# Hadhir Business - Order Receiver App User Guide

## Overview

**Hadhir Business** is a comprehensive mobile and web application designed for businesses to efficiently manage orders, handle customer interactions, and integrate with Point of Sale (POS) systems. The app serves as a merchant interface within a larger delivery ecosystem.

## Getting Started

### System Requirements

- Mobile: Android 6.0+ or iOS 12.0+
- Backend: Python 3.8+, MongoDB
- Platform: Centralized delivery platform integration

### Initial Setup

1. Download & Install the app from your distribution channel
2. Create Account with business information
3. Configure Business settings and POS integration
4. Connect to Platform for order management

## Business Registration & Setup

### User Registration

- Email: Enter valid business email address
- Password: Minimum 8 characters (uppercase, lowercase, number)
- Business Name: Your business display name
- Phone: Contact number for customers and drivers
- Business Type: Restaurant, Store, Pharmacy, or Kitchen

### Business Types Supported

- **Restaurant**: Food service establishments
- **Store**: Retail businesses
- **Pharmacy**: Medical and pharmaceutical services
- **Kitchen**: Cloud kitchens and delivery-only establishments

### Business Information

- Address: Complete business location with GPS coordinates
- Operating Hours: Set daily operating schedules
- Contact Details: Phone, email, and emergency contacts
- Business Documents: Upload required licenses and certificates

## Order Management System

### Order Lifecycle

1. Order Received → Customer places order via centralized platform
2. Accept/Reject → Review and respond to incoming orders
3. Preparing → Mark order as being prepared
4. Ready → Notify when order is ready for pickup
5. Driver Assigned → Platform assigns delivery driver
6. Tracking → Real-time delivery tracking
7. Delivered → Order completion confirmation

### Order Status Management

- **Pending**: New orders awaiting acceptance
- **Confirmed**: Accepted orders in preparation
- **Preparing**: Orders being actively prepared
- **Ready**: Orders ready for driver pickup
- **Picked Up**: Orders collected by delivery driver
- **Delivered**: Successfully delivered orders
- **Cancelled**: Cancelled orders with reason codes

### Order Operations

- Accept Orders: Review order details and confirm acceptance
- Update Status: Change order status as preparation progresses
- Add Notes: Include special preparation instructions
- Set Ready Time: Estimate when order will be ready
- Cancel Orders: Cancel with reason (out of stock, etc.)

## POS System Integration

### Supported POS Systems

- **Square**: Complete Square POS integration
- **Toast**: Restaurant-focused POS system
- **Clover**: Merchant payment processing
- **Custom APIs**: Generic REST API integration

### POS Configuration

- System Type: Select your POS provider
- API Endpoint: POS system URL
- API Key: Authentication credentials
- Access Token: OAuth token for secure access
- Location ID: Specific store/location identifier
- Auto-Send: Automatic order forwarding to POS

### POS Features

- Auto Order Sync: Automatically send orders to POS system
- Inventory Updates: Real-time stock level synchronization
- Payment Processing: Handle payments through POS
- Receipt Generation: Automatic receipt creation
- Connection Testing: Verify POS connectivity

## Notification System

### Customer Notifications

The app automatically sends notifications to customers through the centralized platform:

- Order Confirmed: "Your order has been confirmed and is being prepared"
- Preparation Started: "Your order is now being prepared"
- Order Ready: "Your order is ready for pickup"
- Driver Assigned: "Driver [Name] has been assigned to your order"
- Picked Up: "Your order has been picked up and is on the way"
- Delivered: "Your order has been delivered"
- Order Cancelled: "Your order has been cancelled" (with reason)

### Business Notifications

- New Order Alerts: Real-time notifications for incoming orders
- Driver Assignments: Notifications when drivers are assigned
- Platform Updates: System updates and announcements
- Performance Metrics: Daily/weekly business performance reports

## Items & Menu Management

### Menu Categories

- Create Categories: Organize menu items by type
- Default Categories: Auto-generated based on business type
  - Restaurant: Appetizers, Main Courses, Desserts, Beverages
  - Store: Electronics, Clothing, Home & Garden, Books
  - Pharmacy: Prescription, Over-the-Counter, Health & Beauty
  - Kitchen: Meals, Snacks, Beverages, Combos

### Item Management

- Add Items: Create menu items with details
- Item Details: Name, description, price, availability
- Photos: Upload high-quality item images
- Variants: Size, color, options, and modifiers
- Inventory: Track stock levels and availability
- Pricing: Set base prices and promotional rates

### Search & Organization

- Search Items: Find items by name or category
- Filter Options: Filter by availability, category, price range
- Bulk Operations: Update multiple items simultaneously
- Import/Export: CSV import for large menu updates

## Business Analytics & Reports

### Order Statistics

- Total Orders: Daily, weekly, monthly order counts
- Order Status Breakdown: Orders by status (pending, completed, etc.)
- Revenue Tracking: Total sales and average order value
- Peak Hours: Busiest times for order volume
- Customer Analytics: Repeat customers and order frequency

### Performance Metrics

- Preparation Times: Average time to prepare orders
- Acceptance Rate: Percentage of orders accepted vs. rejected
- Customer Satisfaction: Ratings and reviews
- Delivery Success: On-time delivery rates

## Settings & Configuration

### Profile Settings

- Business Information: Update name, address, contact details
- Operating Hours: Set daily schedules and holidays
- Online Status: Toggle business availability
- Notification Preferences: Configure alert settings

### Account Settings

- Password Management: Change password securely
- Email Updates: Update contact email
- Phone Verification: Verify and update phone number
- Account Status: View verification and active status

### POS Settings

- Connection Management: Configure POS system connectivity
- Auto-Send Orders: Enable/disable automatic order forwarding
- API Configuration: Update API keys and endpoints
- Test Connection: Verify POS system connectivity

## Centralized Platform Integration

### Platform Communication

The app integrates with a centralized delivery platform that manages:

- Customer Orders: Orders flow from customer apps through the platform
- Driver Management: Platform assigns and manages delivery drivers
- Payment Processing: Centralized payment handling
- Real-time Tracking: Live order and delivery tracking

### Webhook Endpoints

- Driver Assignment: Receive driver assignment notifications
- Order Status Updates: Send order status changes to platform
- Customer Notifications: Route notifications through platform

### API Integration

- Order Confirmation: Notify platform when orders are accepted
- Status Updates: Send preparation and ready notifications
- Driver Coordination: Receive driver pickup and delivery updates

## Multi-Language Support

### Supported Languages

- English: Complete interface in English
- Arabic: Full Arabic localization with RTL support

### Localized Features

- Menu Items: Translate item names and descriptions
- Business Information: Localized business details
- Customer Communications: Multi-language customer notifications
- POS Integration: Localized POS settings and configurations

## Security & Privacy

### Data Protection

- JWT Authentication: Secure token-based authentication
- Password Security: Encrypted password storage
- API Security: Secure API communications with authentication
- Data Encryption: All sensitive data encrypted in transit and at rest

### Privacy Features

- Customer Data: Secure handling of customer information
- Business Data: Protected business analytics and reports
- Payment Information: PCI-compliant payment data handling
- Access Controls: Role-based access to business features

## Mobile App Features

### Core Functionality

- Real-time Order Management: Live order updates and status changes
- Push Notifications: Instant alerts for new orders and updates
- Offline Capability: Basic functionality during network outages
- Multi-device Sync: Synchronize data across devices

### User Interface

- Intuitive Design: Clean, modern interface optimized for business use
- Quick Actions: Fast access to common order management tasks
- Customizable Dashboard: Personalized business overview
- Responsive Layout: Optimized for phones and tablets

## Troubleshooting

### Common Issues

**Connection Problems**

- Backend Connectivity: Check internet connection and backend status
- POS Integration: Verify POS credentials and endpoint configuration
- Platform Communication: Ensure centralized platform is accessible

**Order Management**

- Orders Not Appearing: Check business online status and platform connection
- Status Updates Failing: Verify API credentials and network connectivity
- Notification Issues: Check notification settings and permissions

**POS Integration**

- Connection Failures: Verify API keys, endpoints, and POS system status
- Order Sync Issues: Check auto-send settings and POS compatibility
- Authentication Errors: Update expired tokens and credentials

### Support Resources

- Help Documentation: In-app help and FAQ section
- Technical Support: Contact support team for technical issues
- Business Support: Get help with business setup and optimization
- Community Forums: Connect with other business users

## Advanced Features

### Custom Integrations

- Custom Webhooks: Set up custom webhook endpoints
- Third-party Integrations: Connect with external business tools
- Business Data Export: Export business data for analysis
- Bulk Operations: Perform operations on multiple orders/items

### Business Intelligence

- Advanced Analytics: Detailed business performance insights
- Predictive Analytics: Forecast demand and optimize operations
- Customer Insights: Understand customer behavior and preferences
- Market Analysis: Compare performance with industry benchmarks

## Support & Resources

### Getting Help

- Email Support: support@hadhir.business
- Phone Support: Available during business hours
- Live Chat: In-app chat support
- Knowledge Base: Comprehensive help articles

### Training Resources

- Video Tutorials: Step-by-step setup and usage guides
- Webinar Training: Live training sessions for new users
- Documentation: Complete API and integration documentation
- Best Practices: Guidelines for optimal app usage

### Updates & Maintenance

- Automatic Updates: App updates delivered automatically
- Feature Releases: Regular new feature rollouts
- Bug Fixes: Rapid response to reported issues
- Performance Improvements: Ongoing optimization and enhancements

## Success Tips

### Optimize Your Operations

1. Quick Response: Accept orders promptly to improve customer satisfaction
2. Accurate Timing: Provide realistic preparation time estimates
3. Clear Communication: Use order notes for special instructions
4. Regular Updates: Keep menu and availability information current
5. Monitor Analytics: Use performance data to optimize operations

### Maximize Integration Benefits

- POS Sync: Enable auto-send for seamless order management
- Inventory Management: Keep stock levels updated in real-time
- Customer Data: Use customer insights to improve service
- Driver Coordination: Communicate effectively with delivery drivers

---

This comprehensive guide covers all aspects of the Hadhir Business Order Receiver App, from initial setup to advanced features. For additional support or specific questions, please refer to the support resources or contact our help team.
