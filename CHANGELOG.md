# Changelog

All notable changes to this project are documented in this file.

## [v1.0.0] - 2025-06-25

### Added
- **Complete User Guide**: Comprehensive documentation for app usage
- **Order Management System**: Full order lifecycle management
- **POS Integration**: Support for Square, Toast, Clover, and custom APIs
- **Centralized Platform Integration**: Webhook and API communication
- **Customer Notification Service**: Real-time customer notifications
- **Multi-language Support**: English and Arabic localization
- **Business Analytics**: Performance metrics and reporting
- **Security Features**: JWT authentication and data encryption

### Architecture
- **FastAPI Backend**: Modern Python API server
- **MongoDB Database**: Document-based data storage
- **Flutter Frontend**: Cross-platform mobile application
- **OOP Design**: Clean object-oriented architecture

### Documentation
- **User Guide**: Complete app usage documentation
- **Platform Architecture**: Centralized platform integration guide
- **Deployment Template**: Ready-to-deploy platform starter
- **API Documentation**: Comprehensive endpoint documentation

### Production Ready
- ✅ Complete order management workflow
- ✅ POS system integrations
- ✅ Platform communication
- ✅ Customer notifications
- ✅ Business analytics
- ✅ Security and authentication
- ✅ Multi-language support

## [v0.1-snapshot-2025-06-19]

- Extracted business model classes (`Restaurant`, `Store`, `Kitchen`, `Pharmacy`) into `lib/models/businesses/`.
- Consolidated `OrderItem` into `lib/models/order_item.dart`; removed duplicate definitions.
- Updated `lib/models/business.dart` imports to reference single `OrderItem` source.
- Refactored constructors and interfaces to implement `Business` abstract class cleanly in each model.
- Verified application builds and runs on iOS simulator.

*This file is maintained manually.*
