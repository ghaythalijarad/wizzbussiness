# Changelog

All notable changes to this project are documented in this file.

## [v0.1-snapshot-2025-06-19]
- Extracted business model classes (`Restaurant`, `Store`, `Kitchen`, `Pharmacy`) into `lib/models/businesses/`.
- Consolidated `OrderItem` into `lib/models/order_item.dart`; removed duplicate definitions.
- Updated `lib/models/business.dart` imports to reference single `OrderItem` source.
- Refactored constructors and interfaces to implement `Business` abstract class cleanly in each model.
- Verified application builds and runs on iOS simulator.


*This file is maintained manually.*
